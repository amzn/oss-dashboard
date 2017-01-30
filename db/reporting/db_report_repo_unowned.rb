# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

class RepoUnownedDbReporter < DbReporter

  def name()
    return "No Committers"
  end

  def report_class()
    return 'repo-report'
  end

  def describe()
    return "This report shows repositories that have no team committers. \nThey may have collaborators, or oss-dashboard may not have had the permissions to see team data. "
  end

  def db_columns()
    return [ 'Date', ['repository', 'org/repo'] ]
  end

  def db_report(context, org, sync_db)
    # repos with empty teams
    emptyteam=sync_db["SELECT r.name, r.created_at FROM repository r, team_to_repository ttr WHERE ttr.team_id NOT IN (SELECT DISTINCT(team_id) FROM team_to_member) AND ttr.repository_id=r.id AND r.org=?", org]
    # repos with no team
    noteam=sync_db["SELECT r.name, r.created_at FROM repository r WHERE r.id NOT IN (SELECT DISTINCT repository_id FROM team_to_repository) AND r.org=?", org]

    text = ''
    emptyteam.concat(noteam).each do |row|
      text << "  <reporting class='repo-report' repo='#{org}/#{row[:name]}' type='RepoUnownedDbReporter'><field>#{row[:created_at]}</field><field>#{org}/#{row[:name]}</field></reporting>\n"
    end

    return text
  end

end
