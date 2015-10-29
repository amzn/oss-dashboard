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

#### MAIN CODE ####

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

commit_db=db_open(File.join(File.dirname(__FILE__), '../db/gh-sync.db'));

organizations.each do |org|
  getLatestForOrgRepos(client, commit_db, org)
end
