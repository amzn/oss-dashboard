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

class TeamEmptyDbReporter < DbReporter

  def name()
    return "Empty Teams"
  end

  def describe()
    return "This report shows teams that lack any members. "
  end

  def db_columns()
    return [ ['team', 'org/team'] ]
  end

  def db_report(org, sync_db)
    empty=sync_db.execute("SELECT DISTINCT(t.slug) FROM team t, team_to_repository ttr, repository r WHERE t.id NOT IN (SELECT DISTINCT(team_id) FROM team_to_member) AND t.id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?", [org])
    text = ''
    empty.each do |row|
      text << "  <db-reporting type='TeamEmptyDbReporter'><field>#{org}/#{row[0]}</field></db-reporting>\n"
    end
    return text
  end

end
