#!/usr/bin/env ruby

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

require 'yaml'
require_relative '../../util.rb'

queries = [
  ["SELECT COUNT(*) as EventData FROM events", " WHERE org=?"],
  ["SELECT COUNT(*) as ReleaseData FROM releases", " WHERE org=?"],
  ["SELECT COUNT(*) as CommitData FROM commits", " WHERE org=?"],
  ["SELECT COUNT(*) as IssueData FROM issues", " WHERE org=?"],
  ["SELECT COUNT(*) as PullRequestData FROM pull_requests", " WHERE org=?"],
  ["SELECT COUNT(*) as PullRequestFileData FROM pull_request_files pf", ", pull_requests pr WHERE pr.id=pf.pull_request_id AND pr.org=?"],
  ["SELECT COUNT(*) as LabelData FROM labels", " WHERE orgrepo LIKE ?"],
  ["SELECT COUNT(*) as Item2LabelData FROM item_to_label itl", ", labels l WHERE l.url=itl.url AND orgrepo LIKE ?"],
  ["SELECT COUNT(*) as MilestoneData FROM milestones", " WHERE orgrepo LIKE ?"],
  ["SELECT COUNT(*) as Item2MilestoneData FROM item_to_milestone itm", ", milestones m WHERE m.id=itm.milestone_id AND orgrepo LIKE ?"],
  ["SELECT COUNT(*) as OrganizationData FROM organization", " WHERE login=?"],
  ["SELECT COUNT(DISTINCT(t.id)) as TeamData FROM team t", ", team_to_repository ttr, repository r WHERE t.id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?"],
  ["SELECT COUNT(*) as RepositoryData FROM repository", " WHERE org=?"],
  ["SELECT COUNT(DISTINCT(m.id)) as MemberData FROM member m", ", team_to_member ttm, team_to_repository ttr, repository r WHERE m.id=ttm.member_id AND ttm.team_id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?"],
  ["SELECT COUNT(*) as Team2RepoData FROM team_to_repository ttr", ", repository r WHERE ttr.repository_id=r.id AND r.org=?"],
  ["SELECT COUNT(DISTINCT(ttm.member_id || ttm.team_id)) as Team2MemberData FROM team_to_member ttm", ", team_to_repository ttr, repository r WHERE ttm.team_id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?"],
  ["SELECT COUNT(DISTINCT(otm.member_id)) as Organization2MemberData FROM organization_to_member otm", ", organization o WHERE otm.org_id=o.id AND o.login=?"],
  ["SELECT COUNT(DISTINCT(rtm.member_id)) as Repository2MemberData FROM repository_to_member rtm", ", repository r WHERE rtm.repository_id=r.id AND r.org=?"]
]

config = YAML.load_file(DB_CONFIG)
org = ARGV[0]

unless db_exists?(config)
  puts 'Database does not exist'
  exit
end

sync_db = get_db_handle(config)

if(org)
  puts "#{org} Table Size"
  puts "=" * org.length + "==========="
else
  puts "Database Table Size"
  puts "==================="
end

queries.each do |query, clause|
  if(org)
    # Assumed that LIKE clauses are starts-with
    if(clause.include?('LIKE'))
      result=sync_db.query(query+clause, [org+'%'])
    else
      result=sync_db.query(query+clause, [org])
    end
  else
    result=sync_db.query(query)
  end
  puts "#{result.columns[0]}: #{result.next[0]}"
  result.close # CHK TODO need to see what we're getting here
end
