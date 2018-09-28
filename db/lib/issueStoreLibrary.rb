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
        db["DELETE FROM items WHERE id=?", item.id.to_s].delete
        assignee=item.assignee ? item.assignee.login : nil
        user=item.user ? item.user.login : nil
        pr=item.pull_request ? item.pull_request.html_url : nil
        db[
         "INSERT INTO items (
               id, item_number, assignee_login, user_login, state, title, body,
               org, repo, created_at, updated_at, comment_count,
               pull_request_url, merged_at, closed_at
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
            item.id, item.number, assignee, user, item.state, item.title, item.body,
            org, repo, gh_to_db_timestamp(item.created_at), gh_to_db_timestamp(item.updated_at), item.comments,
            pr, gh_to_db_timestamp(item.merged_at), gh_to_db_timestamp(item.closed_at)].insert
    end
  end

  # Inserts new comments. If any exist already, it replaces them.
  def db_insert_comments(db, comments, org, repo)
    comments.each do |comment|
        db["DELETE FROM item_comments WHERE id=?", comment.id].delete
        # eg: https://github.com/amzn/oss-dashboard/issues/13#issuecomment-155591520
        itemNumber=comment.html_url.sub(/^.*\/([0-9]*)#issuecomment-[0-9]*$/, '\1')
        user=comment.user ? comment.user.login : nil
        db[
         "INSERT INTO item_comments (
               id, org, repo, item_number, user_login, body, created_at, updated_at
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )",
          comment.id, org, repo, itemNumber, user, comment.body, gh_to_db_timestamp(comment.created_at),
          gh_to_db_timestamp(comment.updated_at)].insert
    end
  end

  # Inserts new comments. If any exist already, it replaces them.
  def db_insert_pr_reviews(db, comments, org, repo)
    comments.each do |comment|
        db["DELETE FROM item_comments WHERE id=?", comment.id].delete
        # eg: https://github.com/amzn/oss-dashboard/pull/1#discussion_r207199796
        itemNumber=comment.html_url.sub(/^.*\/([0-9]*)#discussion_r[0-9]*$/, '\1')
        user=comment.user ? comment.user.login : nil
        db[
         "INSERT INTO item_comments (
               id, org, repo, item_number, user_login, body, created_at, updated_at
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )",
          comment.id, org, repo, itemNumber, user, comment.body, gh_to_db_timestamp(comment.created_at),
          gh_to_db_timestamp(comment.updated_at)].insert
    end
 end

 def db_getMaxCommentTimestampForRepo(db, org, repo)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db["select max(updated_at) from item_comments where org='#{org}' and repo='#{repo}'"].each do |row|
      timestamp=row[:max]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  def db_getMaxTimestampForRepo(db, org, repo)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db["select max(updated_at) from items where org='#{org}' and repo='#{repo}'"].each do |row|
      timestamp=row[:max]
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
    db["select max(updated_at) from items where org='#{org}'"].each do |row|
      timestamp=row[:max]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  # Update PR to set its merged_at
  def db_update_pull_request(db, pr, org, repo)
    db[
       "UPDATE items SET merged_at=? WHERE org=? AND repo=? AND item_number=?",
        gh_to_db_timestamp(pr.merged_at), org, repo, pr.number.to_s].update
  end

  # Given a list of issues, fix the merged_at for any prs in that list
  def db_fix_merged_at(db, client, issues, org, repo)
    issues.each do |item|
      if(item.pull_request)
        # sqlite queries much cheaper than github requests, so protect from unnecessary github requests
        countRow = db["SELECT COUNT(id) FROM pull_requests WHERE org=? AND repo=? AND pr_number=? AND merged_at IS NOT NULL", org, "#{repo}", item.number.to_s]
        count = countRow.first[:count]
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
    return db["SELECT pull_request_id FROM pull_request_files WHERE pull_request_id=? AND filename=?", id.to_s, filename].first
  end

  # Add the list of files included in a pull request, and more importantly the stats
  def db_add_pull_request_files(db, client, issues, org, repo)
    issues.each do |item|
      if(item.pull_request)
       begin
        files=client.pull_request_files("#{org}/#{repo}", item.number.to_i)
        files.each do |file|
          if(db_pull_request_file_stored?(db, item.id, file.filename))
            db["DELETE FROM pull_request_files WHERE pull_request_id=? AND filename=?", item.id.to_s, file.filename].delete
          end
          db[
            "INSERT INTO pull_request_files (pull_request_id, filename, additions, deletions, changes, status)
               VALUES (?, ?, ?, ?, ?, ?)",
            item.id, file.filename, file.additions, file.deletions, file.changes, file.status].insert
        end
       rescue Octokit::InternalServerError
        # 500 - Server Error: Sorry, there was a problem generating this diff. The repository may be missing relevant data. (Octokit::InternalServerError)
        # Skipping
       end
      end
    end
  end

  def db_link_issues(db, issues, org, repo)
    # For each issue
    issues.each do |issue|
      ## COMMENTING OUT MILESTONES. NO VALUE IN GRABBING DATA CURRENTLY AND LINKING DOESN'T SEEM TO BE WORKING.
      # Remove from item_to_milestone
      #db["DELETE FROM item_to_milestone WHERE item_id=?", issue.id].delete
      # For each milestone
      #if(issue.milestones)
        #issue.milestones.each do |milestone|
          # Insert into item_to_milestone
          #db["INSERT INTO item_to_milestone (item_id, milestone_id) VALUES(?, ?)", item.id, milestone.id].insert
        #end
      #end
      # Remove from item_to_label
      db["DELETE FROM item_to_label WHERE item_id=?", issue.id].delete
      # For each label
      if(issue.labels)
        issue.labels.each do |label|
          # Insert into item_to_label
          db["INSERT INTO item_to_label (item_id, url) VALUES(?, ?)", issue.id, label.url].insert
        end
      end
    end
  end
