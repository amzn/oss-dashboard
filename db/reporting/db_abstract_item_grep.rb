# Copyright 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class AbstractItemGrepDbReporter < DbReporter

  def report_class()
    return 'issue-report'
  end

  def db_columns()
    return [ ['Created', 'date'], ['issue', 'url'], 'Title', 'Status', ['Labels', 'labels'] ]
  end

  def get_parameter_array()
    raise "No get_parameter_array() function defined by report subclass"
  end

  def db_report(context, repo, sync_db)

    text = ""

    input_array=get_parameter_array()

    terms="{%#{input_array.join('%,%')}%}"

    item_query="SELECT DISTINCT(id) AS did FROM items WHERE body ILIKE ANY(?) AND org=? AND repo=?"
    item_comment_query="SELECT DISTINCT(id) AS did FROM item_comment WHERE body ILIKE ANY(?) AND org=? AND repo=?"

    item_ids=Set.new
    item_ids.merge(sync_db[item_query, terms, repo.owner.login, repo.name].map { |row| row[:did] })
    item_ids.merge(sync_db[item_query, terms, repo.owner.login, repo.name].map { |row| row[:did] })

    # NOTE: This is very boilerplate code. Given a list of item ids, display a table. Consider refactoring
    issue_query="SELECT i.id, i.item_number, i.title, i.state, i.created_at, i.updated_at, i.comment_count FROM items i WHERE i.org=? AND i.repo=? AND i.id IN ?"
    label_query='SELECT l.url, l.name, l.color FROM labels l, item_to_label itl WHERE itl.url=l.url AND item_id=?'

    issue_data=sync_db[issue_query, repo.owner.login, repo.name, item_ids.to_a]
    issue_data.each do |row|
        url="#{context.github_url}/#{repo.full_name}/issues/#{row[:item_number]}"
        title=row[:title].gsub(/&/, "&amp;").gsub(/</, "&lt;")

        label_data=sync_db[label_query, row[:id]]
        labels=""
        if(label_data)
          label_data.each do |label|
            labelName=label[:name].gsub(/ /, '&#xa0;')
            labels << "<label url=\"#{escape_amp(label[:url])}\" color='#{label[:color]}'>#{escape_amp(labelName)}</label>"
          end
        end

        text << "  <reporting class='issue-report' repo='#{repo.full_name}' type='#{self.class.name}'><field>#{row[:created_at]}</field><field>#{url}</field><field>#{title}</field><field>#{row[:state]}</field><field>#{labels}</field></reporting>\n"
    end

    return text
  end

end
