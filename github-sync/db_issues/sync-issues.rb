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
require_relative 'issueStoreLibrary.rb'

# This should speed things up, but it doesn't work for two reasons:
#    1) org_issues seems to be getting empty results
#    2) There's no repo in the results, so data can't be stored
#def getLatestForOrg(client, issue_db, org)
#  maxTimestamp=db_getMaxTimestampForOrg(issue_db, org)               # Get the current max timestamp in the db
#  if(maxTimestamp)
#    issues=client.org_issues(org, { 'state' => 'all', 'since' => maxTimestamp } )
#  else
#    issues=client.org_issues(org, { 'state' => 'all' } )
#  end
#  db_insert_issues(issue_db, issues, org, repo)                   # Insert any new items
#end

def getLatestForOrgRepos(client, issue_db, org)
  client.organization_repositories(org).each do |repo_obj|
    repo=repo_obj.full_name
    maxTimestamp=db_getMaxTimestampForRepo(issue_db, repo)               # Get the current max timestamp in the db
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
      issues=client.list_issues(repo, { 'state' => 'all', 'since' => ts } )
    else
      issues=client.list_issues(repo, { 'state' => 'all' } )
    end
    issue_db.execute("BEGIN TRANSACTION");
    db_insert_issues(issue_db, issues, org, repo)                   # Insert any new items
    db_fix_merged_at(issue_db, client, issues, org, repo_obj.name)      # Put in PR specific data - namely merged_at
    db_add_pull_request_files(issue_db, client, issues, org, repo_obj.name)      # Put in PR specific data - namely the files + their metrics
    issue_db.execute("END TRANSACTION");
  end
end

def sync_issues(dashboard_config, client, sync_db)
  
  organizations = dashboard_config['organizations']
  
  organizations.each do |org|
    getLatestForOrgRepos(client, sync_db, org)
  end

end
