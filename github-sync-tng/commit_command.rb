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
require_relative '../db/lib/commitStoreLibrary.rb'

require_relative 'base_command'

class SyncCommitsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_commits(queue, params[0], params[1])
  end

  def sync_commits(queue, context, sync_db)

    owners = context.dashboard_config['organizations+logins']

    owners.each do |org|

      unless(queue.is_a? FileQueue)
        context.feedback.print "  #{org} "
      end

      if(context.login?(org))
        repos=context.client.repositories(org)
      else
        repos=context.client.organization_repositories(org)
      end

      repos.each do |repo_obj|

        if(repo_obj.size==0)
          # if no commits, octokit errors. Size of zero is close enough to no commits
          # - i.e. the first commit may not get shown for a new repo
          # TODO: Catch the error?
          # context.feedback.print '!'
          next
        end

        queue.push(SyncCommitCommand.new( { 'org' => org, 'repo' => repo_obj.name, 'fork' => repo_obj.fork, 'created_at' => repo_obj.created_at.to_s } ) )

      end

    end

  end

end

class SyncCommitCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]

    org=@args['org']
    repo_name=@args['repo']
    fork=@args['fork']
    created_at=@args['created_at']
    repo_full_name="#{org}/#{repo_name}"

    maxTimestamp=db_commit_max_timestamp_by_repo(sync_db, org, repo_name)               # Get the current max timestamp in the db
    unless(maxTimestamp)
      if(fork)
        maxTimestamp=gh_to_db_timestamp(created_at)
      end
    end
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.strptime(maxTimestamp, '%Y-%m-%dT%H:%M:%S') + Rational(1, 60 * 60 * 24)
      commits=context.client.commits_since(repo_full_name, ts)
    else
      commits=context.client.commits(repo_full_name)
    end
    db_insert_commits(sync_db, commits, org, repo_name)                   # Insert any new items
  end

end
