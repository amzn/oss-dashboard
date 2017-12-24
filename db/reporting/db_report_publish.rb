# Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'rubygems'
require 'yaml'
require_relative 'db_reporter'

class PublishDbReporter < DbReporter

  def name()
    return "Publish Events"
  end

  def report_class()
    return 'repo-report'
  end

  def describe()
    return "This report shows recent publish events, and the traffic data surrounding the launch"
  end

  def db_columns()
    return [ 'Date', ['Repository', 'org/repo'], 'Web Traffic First Week', 'Git Clones First Week' ]
  end

  def db_report(context, repo, sync_db)
    event=sync_db["SELECT e.created_at FROM events e WHERE e.type='PublicEvent' AND e.org=? AND e.repo=? ORDER BY e.created_at DESC", repo.owner.login, repo.full_name].first

    unless(event)
      return
    end

    text = ''
    text << "  <reporting class='repo-report' repo='#{repo.full_name}' type='PublishDbReporter'><field>#{event[:created_at]}</field><field>#{repo.full_name}</field>"

    ['views', 'clones'].each do |table|
      # To do weekly, need to look at the modulo of the recorded_at: EXTRACT(days FROM (recorded_at - '2017-12-04 23:28:06'))::integer % 4
      views_by_day=sync_db["SELECT uniques FROM traffic_#{table}_total WHERE org=? and repo=? and recorded_at > ? ORDER BY recorded_at LIMIT 7", repo.owner.login, repo.name, event[:created_at] ].all

      uniques=views_by_day.map { |row| row[:uniques] }
      if(uniques.empty?)
        text << "<field>n/a</field>"
      else
        text << "<field>#{uniques.join(',')}</field>"
      end
    end

    text << "</reporting>\n"

    return text
  end

end
