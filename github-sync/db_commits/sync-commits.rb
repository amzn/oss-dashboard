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

def sync_commits(feedback, dashboard_config, client, sync_db)
  
  organizations = dashboard_config['organizations']

  feedback.puts " commits"
  organizations.each do |org|
    feedback.print "  #{org} "

    client.organization_repositories(org).each do |repo_obj|
      if(repo_obj.size==0)
        # if no commits, octokit errors. Size of zero is close enough to no commits 
        # - i.e. the first commit may not get shown for a new repo
        # TODO: Catch the error?
        feedback.print '!'
        next
      end
      repo_name=repo_obj.name
      repo_full_name=repo_obj.full_name
      maxTimestamp=db_commit_max_timestamp_by_repo(sync_db, org, repo_name)               # Get the current max timestamp in the db
      if(maxTimestamp)
        # Increment the timestamp by a second to avoid getting repeats
        ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
        commits=client.commits_since(repo_full_name, ts)
      else
        commits=client.commits(repo_full_name)
      end
      db_insert_commits(sync_db, commits, org, repo_name)                   # Insert any new items
      feedback.print '.'
    end
    feedback.print "\n"
  end

end
