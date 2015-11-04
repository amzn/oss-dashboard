#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'yaml'
require_relative 'github-pull/pull_source'
require_relative 'review-repos/reporter_runner'
require_relative 'generate-dashboard/generate-dashboard-xml'

# Dashboard configuration
config_file = ARGV[0]    # File.join(File.dirname(__FILE__), "config-dashboard.yml")
config = YAML.load(File.read(config_file))
dashboard_config = config['dashboard']

# GitHub setup
config_file = ARGV[1]    # File.join(File.dirname(__FILE__), "config-github.yml")
config = YAML.load(File.read(config_file))
github_config = config['github']

Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => github_config['access_token'], :accept => 'application/vnd.github.moondragon+json' 

run_one=ARGV[2]

if(not(run_one) or run_one=='pull-source')
  pull_source(dashboard_config, client)
end
if(not(run_one) or run_one=='review-source')
  review_source(dashboard_config, client)
end
if(not(run_one) or run_one=='generate-dashboard')
  generate_dashboard_xml(dashboard_config, client)
end
