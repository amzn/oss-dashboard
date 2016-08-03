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

#require 'filequeue'
require_relative 'fixed_filequeue'

require_relative 'base_command'
require_relative 'release_command'
require_relative 'event_command'
require_relative 'issue_command'
require_relative 'issue_comment_command'
require_relative 'commit_command'
require_relative 'metadata_command'

require_relative '../db/user_mapping/sync-users.rb'
require_relative '../db/reporting/db_reporter_runner.rb'

def eval_queue(queue, context, sync_db)
  while(not queue.empty?)
    cmd=BaseCommand.instantiate(queue.pop)

    begin
      passed=cmd.run(queue, context, sync_db)
      if(passed==false)
        puts "COMMAND DID NOT SUCCEED. BREAKING. "
        break
      end
    rescue Octokit::TooManyRequests => msg
      puts "Out of requests, pushing command back on queue"
      queue.push(cmd)
      break
    rescue Faraday::TimeoutError => msg
      puts "GitHub API timing out, pushing command back on queue"
      queue.push(cmd)
      break
    end

  end
end

def github_sync(context, run_one)

  if(context.client.rate_limit.remaining==0)
    puts "No requests available - cancelling sync"
    return
  end

  queue_filename=File.join(context.dashboard_config['data-directory'], 'db', 'oss-dashboard.queue');
  queue = FileQueue.new queue_filename

  db_filename=File.join(context.dashboard_config['data-directory'], 'db', 'gh-sync.db');
  sync_db=SQLite3::Database.new db_filename

  unless(queue.empty?)
    eval_queue(queue, context, sync_db)
  end

  if(not(run_one) or run_one=='github-sync/metadata')
    queue.push(SyncMetadataCommand.new(Hash.new))
  end
  if(not(run_one) or run_one=='github-sync/commits')
    queue.push(SyncCommitsCommand.new(Hash.new))
  end
  if(not(run_one) or run_one=='github-sync/events')
    queue.push(SyncEventsCommand.new(Hash.new))
  end
  if(not(run_one) or run_one=='github-sync/issues')
    queue.push(SyncIssuesCommand.new(Hash.new))
  end
  if(not(run_one) or run_one=='github-sync/issue-comments')
    queue.push(SyncIssueCommentsCommand.new(Hash.new))
  end
  if(not(run_one) or run_one=='github-sync/releases')
    queue.push(SyncReleasesCommand.new(Hash.new))
  end

  eval_queue(queue, context, sync_db)

  if(not(run_one) or run_one=='github-sync/user-mapping')
    sync_user_mapping(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/reporting')
    run_db_reports(context, sync_db)
  end

  sync_db.close

end

