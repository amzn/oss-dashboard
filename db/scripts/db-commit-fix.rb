#!/usr/bin/env ruby

# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# This converts GitHub commit data to use, whenever possible,
# the GitHub login instead of the Git user.name field
# oss-dashboard changed to do this in a7d4a0b28f5742623a928f106811eac8c0f99c53
# but old data needs fixing if you don't want to simply reload all the github data
#
# It takes a dashboard file (for db credentials), a gitconfig file, and the org to run
# it on.

require 'yaml'
require 'octokit'
require_relative '../../util.rb'

config_file = ARGV[0]
config = YAML.load(File.read(config_file))
dashboard_config = config['dashboard']
gh_config_file = ARGV[1]
gh_config = YAML.load(File.read(gh_config_file))
access_token ||= gh_config['github']['access_token']
org = ARGV[2]

unless db_exists?(dashboard_config)
  puts 'Database does not exist'
  exit
end

db = get_db_handle(dashboard_config)

Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => access_token

result=db["SELECT distinct(repo) FROM commits WHERE org=?", org]

db.transaction do
  result.each do |row|
    repo=row[:repo]

    # get the commits for that repo
    begin
      commits=client.commits("#{org}/#{repo}")
    rescue Octokit::NotFound => onf
      puts "Skipping #{org}/#{repo} as not found"
      next
    end

    # loop over each commit
    commits.each do |commit|

      if(commit['committer'])
        db["UPDATE commits SET committer=? WHERE sha=?", commit['committer']['login'], commit[:sha]].update
      end

      if(commit['author'])
        db["UPDATE commits SET author=? WHERE sha=?", commit['author']['login'], commit[:sha]].update
      end

    end

  end
end
