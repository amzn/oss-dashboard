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

require 'fileutils'

#require 'filequeue'
require_relative 'fixed_filequeue'

require_relative 'base_command'
require_relative 'release_command'
require_relative 'event_command'
require_relative 'issue_command'
require_relative 'issue_comment_command'
require_relative 'commit_command'
require_relative 'metadata_command'
require_relative 'traffic_command'

require_relative '../db/user_mapping/sync-users.rb'
require_relative '../db/reporting/db_reporter_runner.rb'
require_relative '../util.rb'

def eval_queue(queue, context, sync_db)
  return_code=true

  # If we fail more than limit times, give up.
  # Sometimes a fail is just a repo being deleted and getting a 404, so soldier on
  fail=0
  limit=10

  while(not queue.empty?)
    queue_obj=queue.pop
    if(queue_obj.is_a? BaseCommand)
      cmd=queue_obj
    else
      cmd=BaseCommand.instantiate(queue_obj)
    end

    begin
      passed=cmd.run(queue, context, sync_db)
      if(passed==false)
        context.feedback.puts "!"
        return false
      else
        context.feedback.print "."
      end
    rescue Octokit::TooManyRequests => msg
      puts "Out of requests, pushing command back on queue: #{msg}"
      queue.push(cmd)
      return_code=false
      break
    rescue Faraday::TimeoutError => msg
      puts "GitHub API timing out, pushing command back on queue: #{msg}"
      queue.push(cmd)
      if(fail > limit)
        return_code=false
        break
      else
        fail=fail+1
      end
    rescue Octokit::ClientError => msg
      # Repository access blocked (Octokit::ClientError)
      puts "GitHub client error, pushing command back on queue: #{msg}"
      queue.push(cmd)
      if(fail > limit)
        return_code=false
        break
      else
        fail=fail+1
      end
    end

  end
  context.feedback.puts
  return return_code
end

def empty_queue(context)
  queue_filename=File.join(context.dashboard_config['data-directory'], 'oss-dashboard.queue');
  queue = FileQueue.new queue_filename
  unless(queue.empty?)
    # remove the queue
    backup_filename="#{queue_filename}.bckp"
    puts "Moving queue containing #{queue.length} items to #{backup_filename}"
    FileUtils.mv(queue_filename, backup_filename)
  end
end

def github_sync(context, run_one)

  if(context.client.rate_limit.remaining==0)
    puts "No requests available - cancelling sync"
    return
  end

  queue_filename=File.join(context.dashboard_config['data-directory'], 'oss-dashboard.queue');
  queue = FileQueue.new queue_filename

  sync_db = get_db_handle(context.dashboard_config)

  # Normal behaviour is to flush the queue
  unless(context[:queueonly])
    unless(queue.empty?)
      context.feedback.print "\n flushing queue\n  "
      flushed=eval_queue(queue, context, sync_db)
      unless(flushed)
        return
      end
    end
  end

  # Also flush the queue if it's specifically been asked
  if(context[:flushonly])
    context.feedback.print "\n flushing queue\n  "
    flushed=eval_queue(queue, context, sync_db)
    return
  end

  # The queue was flushed, or we're in queueonly mode, so go ahead and queue
  if(not(run_one) or run_one=='github-sync/metadata')
    context.feedback.puts "  github-sync/metadata: queueing"
    queue.push(SyncMetadataCommand.new)
  end
  if(not(run_one) or run_one=='github-sync/commits')
    context.feedback.puts "  github-sync/commits: queueing"
    queue.push(SyncCommitsCommand.new)
  end
  if(not(run_one) or run_one=='github-sync/events')
    context.feedback.puts "  github-sync/events: queueing"
    queue.push(SyncEventsCommand.new)
  end
  if(not(run_one) or run_one=='github-sync/issues')
    context.feedback.puts "  github-sync/issues: queueing"
    queue.push(SyncIssuesCommand.new)
  end
  if(not(run_one) or run_one=='github-sync/issue-comments')
    context.feedback.puts "  github-sync/issue-comments: queueing"
    queue.push(SyncIssueCommentsCommand.new)
  end
  if(not(run_one) or run_one=='github-sync/releases')
    context.feedback.puts "  github-sync/releases: queueing"
    queue.push(SyncReleasesCommand.new)
  end
  if(not(run_one) or run_one=='github-sync/traffic')
    context.feedback.puts "  github-sync/traffic: queueing"
    queue.push(SyncTrafficCommand.new)
  end

  unless(context[:queueonly])
    context.feedback.print "\n evaluating queue\n  "
    eval_queue(queue, context, sync_db)
  end

  if(not(run_one) or run_one=='github-sync/user-mapping')
    context.feedback.puts "  github-sync/user-mapping"
    sync_user_mapping(context, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/reporting')
    context.feedback.puts "  github-sync/reporting"
    run_db_reports(context, sync_db)
  end

  sync_db.disconnect

end

