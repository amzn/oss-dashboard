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
require 'octokit'
require 'date'
require 'yaml'

require_relative 'db_metadata/sync-metadata.rb'
require_relative 'db_events/sync-events.rb'
require_relative 'db_issues/sync-issues.rb'
require_relative 'db_releases/sync-releases.rb'
require_relative '../db/user_mapping/sync-users.rb'
require_relative '../db/reporting/db_reporter_runner.rb'
require_relative '../util.rb'

require_relative '../github-sync-tng/sync.rb'
require_relative '../github-sync-tng/commit_command.rb'
require_relative '../github-sync-tng/traffic_command.rb'

class AsyncQueue < Queue

  def initialize(context, sync_db)
    super()
    @context=context
    @sync_db=sync_db
  end

  def push(obj)
    super(obj)
    eval_queue(self, @context, @sync_db)
  end

end

def github_sync(context, run_one)

  sync_db = get_db_handle(context.dashboard_config)

  if(not(run_one) or run_one=='github-sync/metadata')
    sync_metadata(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/commits')
    context.feedback.puts ' commits'
    queue=AsyncQueue.new(context, sync_db)
    queue.push(SyncCommitsCommand.new)
    context.feedback.print "\n"
  end
  if(not(run_one) or run_one=='github-sync/events')
    sync_events(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/issues')
    sync_issues(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/issue-comments')
    sync_issue_comments(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/releases')
    sync_releases(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/traffic')
    context.feedback.puts ' traffic'
    queue=AsyncQueue.new(context, sync_db)
    queue.push(SyncTrafficCommand.new)
    context.feedback.print "\n"
  end
  if(not(run_one) or run_one=='github-sync/user-mapping')
    sync_user_mapping(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/reporting')
    run_db_reports(context, sync_db)
  end

  sync_db.disconnect

end

