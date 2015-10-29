#!/usr/bin/env ruby

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

def sync_issues
  # Dashboard configuration
  config_file = File.join(File.dirname(__FILE__), "../../config-dashboard.yml")
  config = YAML.load(File.read(config_file))
  dashboard_config = config['dashboard']
  
  organizations = dashboard_config['organizations']
  
  # GitHub setup
  config_file = File.join(File.dirname(__FILE__), "../../config-github.yml")
  config = YAML.load(File.read(config_file))
  github_config = config['github']
  
  Octokit.auto_paginate = true
  client = Octokit::Client.new :access_token => github_config['access_token'], :accept => 'application/vnd.github.moondragon+json' 
  
  issue_db=db_open(File.join(File.dirname(__FILE__),'../db/gh-sync.db'));
  
  organizations.each do |org|
    getLatestForOrgRepos(client, issue_db, org)
  end
end

# Invoke from command line
if __FILE__ == $0
  sync_issues
end
