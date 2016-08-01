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

class UnknownMembersDbReporter < DbReporter

  def name()
    return "Unknown Members"
  end

  def report_class()
    return 'user-report'
  end

  def describe()
    return "This report shows which of the organization members are not in your user_mapping of GitHub login to Internal Employee login. "
  end

  def db_columns()
    return [ ['login', 'member'], 'org' ]
  end

  def db_report(context, org, sync_db)
    unknown=sync_db.execute("SELECT DISTINCT(m.login) FROM member m, repository r, team_to_member ttm, team_to_repository ttr WHERE m.login NOT IN (SELECT login FROM users) AND m.id=ttm.member_id AND ttm.team_id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?", [org])
    text = ''
    unknown.each do |row|
      text << "  <reporting class='user-report' type='UnknownMembersDbReporter'><field>#{row[0]}</field><field>#{org}</field></reporting>\n"
    end
    return text
  end

end
