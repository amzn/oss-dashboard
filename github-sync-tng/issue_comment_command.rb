# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'octokit'
require 'date'
require_relative '../db/lib/issueStoreLibrary.rb'

require_relative 'base_command'

# [GitHub Client Calls = COUNT(Repos)]
class SyncIssueCommentsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_issue_comments(queue, params[0], params[1])
  end

  def sync_issue_comments(queue, context, sync_db)
    owners = context.dashboard_config['organizations+logins']

    owners.each do |org|

      if(context.login?(org))
        repos=context.client.repositories(org)
      else
        repos=context.client.organization_repositories(org)
      end

      repos.each do |repo_obj|
        queue.push(SyncItemCommentsCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
      end
    end

  end

end

# [GitHub Client Calls = 1]
class SyncItemCommentsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_item_comments(params[0], params[1], @args['org'], @args['repo'])
  end

  def sync_item_comments(context, issue_db, org, repo)
    orgrepo="#{org}/#{repo}"

    issue_db.execute("BEGIN TRANSACTION");
    # Get the current max timestamp in the db
    maxTimestamp=db_getMaxCommentTimestampForRepo(issue_db, repo)
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.strptime(maxTimestamp, '%Y-%m-%dT%H:%M:%S') + Rational(1, 60 * 60 * 24)
      comments=context.client.issues_comments(orgrepo, { 'since' => ts } )
    else
      comments=context.client.issues_comments(orgrepo)
    end
    db_insert_comments(issue_db, comments, org, repo)
    issue_db.execute("COMMIT");
  end

end

