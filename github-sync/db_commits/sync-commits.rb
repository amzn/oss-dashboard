#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'date'
require 'yaml'
require_relative 'commitStoreLibrary.rb'

def getLatestForOrgRepos(client, commit_db, org)
  client.organization_repositories(org).each do |repo_obj|
    if(repo_obj.size==0)
      # if no commits, octokit errors. Size of zero is close enough to no commits 
      # - i.e. the first commit may not get shown for a new repo
      puts "Not grabbing commit data as #{repo_obj.full_name} is virtually empty"
      next
    end
    repo_name=repo_obj.name
    repo_full_name=repo_obj.full_name
    maxTimestamp=db_getMaxTimestampForRepo(commit_db, org, repo_name)               # Get the current max timestamp in the db
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
      commits=client.commits_since(repo_full_name, ts)
    else
      commits=client.commits(repo_full_name)
    end
    db_insert_commits(commit_db, commits, org, repo_name)                   # Insert any new items
  end
end

def sync_commits(dashboard_config, client, sync_db)
  
  organizations = dashboard_config['organizations']

  organizations.each do |org|
    getLatestForOrgRepos(client, sync_db, org)
  end

end
