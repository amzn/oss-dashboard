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
require_relative 'eventStoreLibrary.rb'

# NOTE: This should really use ETags, but as Octokit doesn't provide support 
# (outside of faraday caches that I've not tried), we'll do extra calls
# TODO: If no access to org, use organization_public_events
# NOTE: BUG: It seems that this does not pull WatchEvents (i.e. stars). Repo calls do.  
def getLatestForOrg(client, event_db, org)
#  puts "Getting events for #{org}"
  maxId=db_getMaxIdForOrg(event_db, org)               # Get the current max id in the db
  # TODO: Would be nice to simply ask GitHub API if this access token can call this
  begin
    events=client.organization_events(org)               # Get the events for the Org
  rescue Octokit::NotFound => msg
    events=client.organization_public_events(org)               # Get the events for the Org
  end
  if(maxId)
    events.delete_if { |event| event.id <= maxId }     # Delete events that should already be in the db
  end
  db_insert_events(event_db, events)                   # Insert any remaining
end

# TODO: If no access to repo, use repository_public_events
def getAllForOrg(client, event_db, org)
  client.organization_repositories(org).each do |repo_obj|
    repo=repo_obj.full_name
#    puts "Getting events for #{repo}"
    maxId=db_getMaxIdForRepo(event_db, repo)           # Get the current max id in the db
    events=client.repository_events(repo)              # Get the events for the Repo
    if(maxId)
      events.delete_if { |event| event.id <= maxId }   # Delete events that should already be in the db
    end
    db_insert_events(event_db, events)                 # Insert any remaining
  end
end


def sync_events(context, sync_db)
  
  organizations = context.dashboard_config['organizations']
  context.feedback.puts " events"
  
  organizations.each do |org|
    # TODO: Access db to see if any entries. If none, then use this call. Otherwise use latest.
    #getAllForOrg(client, sync_db, org)
    context.feedback.print "  #{org} "
    getLatestForOrg(context.client, sync_db, org)
    context.feedback.print "\n"
  end

end
