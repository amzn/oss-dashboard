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

def getMilestones(client, db, orgrepo)
  milestones=client.milestones(orgrepo)
  if(milestones.empty?)
    return
  end
  # Wipe Milestones
  db.execute("DELETE FROM milestones WHERE orgrepo=?", [orgrepo])
  # Fill Milestones again
  milestones.each do |milestone|
    db.execute(
      "INSERT INTO milestones " + 
      "(orgrepo, id, html_url, title, state, number, description, creator, open_issues, closed_issues, created_at, updated_at, closed_at, due_on) " +
      "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [orgrepo, milestone.id, milestone.html_url, milestone.title, milestone.state, milestone.number, milestone.description, milestone.creator.login, milestone.open_issues, milestone.closed_issues, gh_to_db_timestamp(milestone.created_at), gh_to_db_timestamp(milestone.updated_at), gh_to_db_timestamp(milestone.closed_at), gh_to_db_timestamp(milestone.due_on)])
  end
end

def getLabels(client, db, orgrepo)
  labels=client.labels(orgrepo)
  if(labels.empty?)
    return
  end
  # Wipe Labels
  db.execute("DELETE FROM labels WHERE orgrepo=?", [orgrepo])
  # Fill Labels again
  labels.each do |label|
    db.execute("INSERT INTO labels (orgrepo, url, name, color) VALUES (?, ?, ?, ?)", [orgrepo, label.url, label.name, label.color])
  end
end

def db_link_issues(db, issues, org, orgrepo)
  # For each issue
  issues.each do |issue|
    # Remove from item_to_milestone
    db.execute("DELETE FROM item_to_milestone WHERE item_id=?", [issue.id])
    # For each milestone
    if(issue.milestones)
      issue.milestones.each do |milestone|
        # Insert into item_to_milestone
        db.execute("INSERT INTO item_to_milestone (item_id, milestone_id) VALUES(?, ?)", [item.id, milestone.id])
      end
    end
    # Remove from item_to_label
    db.execute("DELETE FROM item_to_label WHERE item_id=?", [issue.id])
    # For each label
    if(issue.labels)
      issue.labels.each do |label|
        # Insert into item_to_label
        db.execute("INSERT INTO item_to_label (item_id, url) VALUES(?, ?)", [issue.id, label.url])
      end
    end
  end
end

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

def getLatestForOrgRepos(feedback, client, issue_db, org)
  client.organization_repositories(org).each do |repo_obj|
    repo=repo_obj.full_name
    issue_db.execute("BEGIN TRANSACTION");
    getMilestones(client, issue_db, repo)
    getLabels(client, issue_db, repo)
    maxTimestamp=db_getMaxTimestampForRepo(issue_db, repo)               # Get the current max timestamp in the db
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
      issues=client.list_issues(repo, { 'state' => 'all', 'since' => ts } )
    else
      issues=client.list_issues(repo, { 'state' => 'all' } )
    end
    db_insert_issues(issue_db, issues, org, repo)                   # Insert any new items
    db_link_issues(issue_db, issues, org, repo)
    db_fix_merged_at(issue_db, client, issues, org, repo_obj.name)      # Put in PR specific data - namely merged_at
    db_add_pull_request_files(issue_db, client, issues, org, repo_obj.name)      # Put in PR specific data - namely the files + their metrics
    issue_db.execute("END TRANSACTION");
    feedback.print '.'
  end
end

def sync_issues(feedback, dashboard_config, client, sync_db)
  
  organizations = dashboard_config['organizations']
  feedback.puts " issues"
  
  organizations.each do |org|
    feedback.print "  #{org} "
    getLatestForOrgRepos(feedback, client, sync_db, org)
    feedback.print "\n"
  end

end
