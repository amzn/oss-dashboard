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
require_relative '../db/lib/eventStoreLibrary.rb'

require_relative 'base_command'

class SyncEventsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_events(queue, params[0], params[1])
  end

  def sync_events(queue, context, sync_db)
  
    owners = context.dashboard_config['organizations+logins']
    context.feedback.puts " events"
  
    owners.each do |org|

      if(context.login?(org))
        # TODO: Get user events?
        next
      end

      ##repos=context.client.organization_repositories(org)

      context.feedback.print "  #{org} "
      queue.push(SyncEventCommand.new( { 'org' => org } ) )   ##, 'repo' => repo_obj.name } ) )
      context.feedback.print "\n"
    end

  end

end

# [GitHub Client Calls = 1-2]
class SyncEventCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]

    getLatestForOrg(context.client, sync_db, @args['org'])
  end

  # NOTE: This should really use ETags, but as Octokit doesn't provide support 
  # (outside of faraday caches that I've not tried), we'll do extra calls
  # TODO: If no access to org, use organization_public_events
  # NOTE: BUG: It seems that this does not pull WatchEvents (i.e. stars). Repo calls do.  
  def getLatestForOrg(client, sync_db, org)
  #  puts "Getting events for #{org}"
    maxId=db_getMaxIdForOrg(sync_db, org)               # Get the current max id in the db
    # TODO: Would be nice to simply ask GitHub API if this access token can call this
    begin
      events=client.organization_events(org)               # Get the events for the Org
    rescue Octokit::NotFound => msg
      events=client.organization_public_events(org)               # Get the events for the Org
    end
    if(maxId)
      events.delete_if { |event| event.id <= maxId }     # Delete events that should already be in the db
    end
    db_insert_events(sync_db, events)                   # Insert any remaining
  end

end
  
    # TODO: Access db to see if any entries. If none, then use this call. Otherwise use latest.
    #getAllForOrg(client, sync_db, @args['org'])
##  # TODO: If no access to repo, use repository_public_events
##  def getAllForOrg(client, sync_db, org)
##    client.organization_repositories(org).each do |repo_obj|
##      repo=repo_obj.full_name
##  #    puts "Getting events for #{repo}"
##      maxId=db_getMaxIdForRepo(sync_db, repo)           # Get the current max id in the db
##      events=client.repository_events(repo)              # Get the events for the Repo
##      if(maxId)
##        events.delete_if { |event| event.id <= maxId }   # Delete events that should already be in the db
##      end
##      db_insert_events(sync_db, events)                 # Insert any remaining
##    end
##  end
