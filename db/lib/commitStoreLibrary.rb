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
require "date"

  def db_insert_commits(db, commits, org, repo)
    begin
      db.transaction do
        commits.each do |commit|
          committer=commit['commit']['committer']['name']
          if(commit['committer'])
            committer=commit['committer']['login']
          end
          author=commit['commit']['author']['name']
          if(commit['author'])
            author=commit['author']['login']
          end

            db[
             "INSERT INTO commits (
                sha, message, tree, org, repo, author, authored_at, committer, committed_at, comment_count
              )
              VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
              commit['sha'],
              commit['commit']['message'],
              commit['commit']['tree']['sha'],
              org,
              repo,
              author,
              gh_to_db_timestamp(commit['commit']['author']['date']),
              committer,
              gh_to_db_timestamp(commit['commit']['committer']['date']),
              commit['commit']['comment_count']
              ].insert
        #puts "  Inserted: #{commit.sha}"
        end
      end
    rescue => e
      puts "Error during processing: #{$!}"
    end

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
    db["select max(committed_at) from commits where org='#{org}' and repo='#{repo}'"].each do |row|
      timestamp=row[:max]
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
    db["select max(committed_at) from commits where org='#{org}'"].each do |row|
      timestamp=row[:max]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end
