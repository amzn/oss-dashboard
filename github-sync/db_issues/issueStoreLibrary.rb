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

  def gh_to_db_timestamp(timestamp)
    # Convert format '2014-10-31 23:21:44 UTC' to '2006-03-10T23:33:03+00:00'
    if(timestamp)
      return timestamp.to_s.sub(/ /,'T').sub(/ UTC/, '+00:00')
    else
      return timestamp
    end
  end

  # Inserts new issues. If any exist already, it replaces them. 
  def db_insert_issues(db, issues, org, repo)
    issues.each do |item|
        db.execute("DELETE FROM items WHERE id=?", item.id)
        assignee=item.assignee ? item.assignee.login : nil
        user=item.user ? item.user.login : nil
        pr=item.pull_request ? item.pull_request.html_url : nil
        db.execute(
         "INSERT INTO items (
               id, item_number, assignee_login, user_login, state, title, body, 
               org, repo, created_at, updated_at, comment_count, 
               pull_request_url, merged_at, closed_at
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
          [item.id, item.number, assignee, user, item.state, item.title, item.body,
           org, repo, gh_to_db_timestamp(item.created_at), gh_to_db_timestamp(item.updated_at), item.comments, 
           pr, gh_to_db_timestamp(item.merged_at), gh_to_db_timestamp(item.closed_at)] )
    end
  end

  # Inserts new comments. If any exist already, it replaces them.
  def db_insert_comments(db, comments, org, repo)
    comments.each do |comment|
        db.execute("DELETE FROM item_comments WHERE id=?", comment.id)
        itemNumber=comment.url.sub(/^.*\/([0-9]*)$/, '\1')
        db.execute(
         "INSERT INTO item_comments (
               id, repo, org, item_number, body, created_at, updated_at
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ? )",
          [comment.id, org, repo, itemNumber, comment.body, gh_to_db_timestamp(comment.created_at), gh_to_db_timestamp(comment.updated_at)]
        )
    end
  end

  def db_getMaxCommentTimestampForRepo(db, repo)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(updated_at) from item_comments where repo='#{repo}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  def db_getMaxTimestampForRepo(db, repo)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(updated_at) from items where repo='#{repo}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  def db_getMaxTimestampForOrg(db, org)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(updated_at) from items where org='#{org}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  # Update PR to set its merged_at
  def db_update_pull_request(db, pr, org, repo)
    db.execute(
       "UPDATE items SET merged_at=? WHERE org=? AND repo=? AND item_number=?",
        [gh_to_db_timestamp(pr.merged_at), org, "#{org}/#{repo}", pr.number] )
  end

  # Given a list of issues, fix the merged_at for any prs in that list
  def db_fix_merged_at(db, client, issues, org, repo)
    issues.each do |item|
      if(item.pull_request)
        # sqlite queries much cheaper than github requests, so protect from unnecessary github requests
        count=db.execute("SELECT COUNT(id) FROM pull_requests WHERE org=? AND repo=? AND pr_number=? AND merged_at IS NOT NULL", [org, "#{org}/#{repo}", item.number] )[0][0]
        if(count == 0)
            pr=client.pull_request( "#{org}/#{repo}", item.number )
            if(pr.merged_at)
              db_update_pull_request(db, pr, org, repo)
            end
        end
      end
    end
  end

  def db_pull_request_file_stored?(db, id, filename)
    return db.execute("SELECT pull_request_id FROM pull_request_files WHERE pull_request_id=? AND filename=?", [id, filename]) != 0
  end

  # Add the list of files included in a pull request, and more importantly the stats
  def db_add_pull_request_files(db, client, issues, org, repo)
    issues.each do |item|
      if(item.pull_request)
        files=client.pull_request_files("#{org}/#{repo}", item.number.to_i)
        files.each do |file|
          if(db_pull_request_file_stored?(db, item.id, file.filename))
            db.execute("DELETE FROM pull_request_files WHERE pull_request_id=? AND filename=?", [item.id, file.filename])
          end
          db.execute(
            "INSERT INTO pull_request_files (pull_request_id, filename, additions, deletions, changes, status) 
               VALUES (?, ?, ?, ?, ?, ?)",
            [item.id, file.filename, file.additions, file.deletions, file.changes, file.status])
        end
      end
    end
  end
