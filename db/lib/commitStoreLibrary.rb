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

require "yaml"
require "sqlite3"
require "date"

  def db_insert_commits(db, commits, org, repo)
    db.execute("BEGIN TRANSACTION");
    commits.each do |commit|
        db.execute(
         "INSERT INTO commits (
            sha, message, tree, org, repo, author, authored_at, committer, committed_at, comment_count
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
        [
         commit['sha'],
         commit['commit']['message'],
         commit['commit']['tree']['sha'],
         org,
         repo,
         commit['commit']['author']['name'],
         gh_to_db_timestamp(commit['commit']['author']['date']),
         commit['commit']['committer']['name'],
         gh_to_db_timestamp(commit['commit']['committer']['date']),
         commit['commit']['comment_count'] 
        ] )
#        puts "  Inserted: #{commit.sha}"
    end
    db.execute("END TRANSACTION");
  end

  def gh_to_db_timestamp(timestamp)
    # Convert format '2014-10-31 23:21:44 UTC' to '2006-03-10T23:33:03+00:00'
    if(timestamp)
      return timestamp.to_s.sub(/ /,'T').sub(/ UTC/, '+00:00')
    else
      return timestamp
    end
  end

  def db_commit_max_timestamp_by_repo(db, org, repo)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(committed_at) from commits where org='#{org}' and repo='#{repo}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  def db_commit_max_timestamp_by_org(db, org)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(committed_at) from commits where org='#{org}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end
