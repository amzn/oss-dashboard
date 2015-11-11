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

require "sqlite3"

queries = [
  "SELECT COUNT(*) as EventData FROM events",
  "SELECT COUNT(*) as ReleaseData FROM releases",
  "SELECT COUNT(*) as CommitData FROM commits",
  "SELECT COUNT(*) as IssueData FROM issues",
  "SELECT COUNT(*) as PullRequestData FROM pull_requests",
  "SELECT COUNT(*) as PullRequestFileData FROM pull_request_files",
  "SELECT COUNT(*) as OrganizationData FROM organization",
  "SELECT COUNT(*) as TeamData FROM team",
  "SELECT COUNT(*) as RepositoryData FROM repository",
  "SELECT COUNT(*) as MemberData FROM member",
  "SELECT COUNT(*) as Team2RepoData FROM team_to_repository",
  "SELECT COUNT(*) as Team2MemberData FROM team_to_member"
]

db_filename = ARGV[0]

unless(File.exists?(db_filename))
  puts "Database does not exist: #{db_filename}"
  exit
end

sync_db=SQLite3::Database.new db_filename

queries.each do |query|
  result=sync_db.query(query)
  puts "#{result.columns[0]}: #{result.next[0]}"
  result.close
end
