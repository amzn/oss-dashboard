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
require_relative 'commitStoreLibrary.rb'

def sync_commits(context, sync_db)
  
  owners = context.dashboard_config['organizations+logins']

  context.feedback.puts " commits"
  owners.each do |org|
    context.feedback.print "  #{org} "

    if(context.login?(org))
      repos=context.client.repositories(org)
    else
      repos=context.client.organization_repositories(org)
    end

#    context.client.organization_repositories(org).each do |repo_obj|
    repos.each do |repo_obj|

     begin
      if(repo_obj.size==0)
        # if no commits, octokit errors. Size of zero is close enough to no commits 
        # - i.e. the first commit may not get shown for a new repo
        # TODO: Catch the error?
        context.feedback.print '!'
        next
      end
      repo_name=repo_obj.name
      repo_full_name=repo_obj.full_name
      maxTimestamp=db_commit_max_timestamp_by_repo(sync_db, org, repo_name)               # Get the current max timestamp in the db
      unless(maxTimestamp)
        if(repo_obj.fork)
          maxTimestamp=gh_to_db_timestamp(repo_obj.created_at.to_s)
        end
      end
      if(maxTimestamp)
        # Increment the timestamp by a second to avoid getting repeats
        ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
        commits=context.client.commits_since(repo_full_name, ts)
      else
        commits=context.client.commits(repo_full_name)
      end
      db_insert_commits(sync_db, commits, org, repo_name)                   # Insert any new items
      context.feedback.print '.'
     rescue Octokit::ClientError
       # Repository access blocked (Octokit::ClientError)
       context.feedback.print "!"
     end
    end
    context.feedback.print "\n"
  end

end
