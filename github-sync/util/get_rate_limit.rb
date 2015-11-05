#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'date'
require 'yaml'

# GitHub setup
config_file = ARGV[0]
config = YAML.load(File.read(config_file))
github_config = config['github']

Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => github_config['access_token'], :accept => 'application/vnd.github.moondragon+json' 

p client.rate_limit
