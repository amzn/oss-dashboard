#!/usr/bin/env ruby

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

# GitHub setup
if(ENV['GH_ACCESS_TOKEN'])
  access_token=ENV['GH_ACCESS_TOKEN']
elsif(ARGV[0])
  config_file = ARGV[0]
  config = YAML.load(File.read(config_file))
  access_token = config['github']['access_token']
else
  puts "ERROR: Need a GitHub access token, either via environment variable (GH_ACCESS_TOKEN) or configuration file. "
  exit
end


Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => access_token, :accept => 'application/vnd.github.moondragon+json' 

p client.rate_limit
