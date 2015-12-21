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

class LeftEmploymentDbReporter < DbReporter

  def name()
    return "Left Employment"
  end

  def describe()
    return "This report shows which of the organization members are flagging as having left the company (per a custom task's updating of the users.is_employee column. "
  end

  def db_columns()
    return [ ['login', 'url'], 'email' ]
  end

  def db_report(org, sync_db)
    unknown=sync_db.execute("SELECT DISTINCT(m.login), u.email FROM member m, repository r, team_to_member ttm, team_to_repository ttr, users u WHERE m.login=u.login AND u.is_employee=0 AND m.id=ttm.member_id AND ttm.team_id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?", [org])
    text = ''
    unknown.each do |row|
      url="https://github.com/orgs/#{org}/people?utf8=%E2%9C%93&amp;query=#{row[0]}"
      text << "  <db-reporting type='LeftEmploymentDbReporter'><field id='#{url}'>#{row[0]}</field><field>#{row[1]}</field></db-reporting>\n"
    end
    return text
  end

end
