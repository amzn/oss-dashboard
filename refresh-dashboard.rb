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
require 'yaml'
require 'xml'
require 'xslt'
require_relative 'github-sync/init-database'
require_relative 'github-sync/sync'
require_relative 'github-pull/pull_source'
require_relative 'review-repos/reporter_runner'
require_relative 'generate-dashboard/generate-dashboard-xml'
require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  options[:ghconfig] = nil
  opts.on( '-g', '--ghconfig FILE', 'Provide GitHub Access Token Configuation File' ) do |file|
    options[:ghconfig] = file
  end
  options[:quiet] = false
  opts.on( '-q', '--quiet', 'Silence the script' ) do
    options[:quiet] = true
  end
end
optparse.parse!

# GitHub setup
if(ENV['GH_ACCESS_TOKEN'])
  access_token=ENV['GH_ACCESS_TOKEN']
elsif(options[:ghconfig])
  config_file = options[:ghconfig]
  config = YAML.load(File.read(config_file))
  access_token = config['github']['access_token']
else
  puts "ERROR: Need a GitHub access token, either via environment variable (GH_ACCESS_TOKEN) or configuration file. "
  puts "Usages: \n    GH_ACCESS_TOKEN=... #{$0} <dashboard-config> [optional-phase]\n    #{$0} --ghconfig <file> <dashboard-config> [optional-phase]"
  exit
end

Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => access_token, :accept => 'application/vnd.github.moondragon+json' 

# Dashboard configuration
config_file = ARGV[0]
config = YAML.load(File.read(config_file))
dashboard_config = config['dashboard']
data_directory = dashboard_config['data-directory']
www_directory = dashboard_config['www-directory']
organizations = dashboard_config['organizations']

unless(File.exists?(data_directory))
  Dir.mkdir(data_directory)
end

run_one=ARGV[1]

# Quiet mode or verbose
feedback=$stdout
if(options[:quiet])
  feedback=File.open(File::NULL, "w")
else
  $stdout.sync = true
end

feedback.puts "Remaining GitHub Calls: #{client.rate_limit.remaining}"

if(File.exists?(File.join(data_directory, 'db', 'gh-sync.db')))
  if(run_one=='init-database')
    feedback.puts "ERROR: Will not initialize over the top of an existing database file. Please remove the database file if reset desired. "
    exit
  end
else
  if(not(run_one) or run_one=='init-database')
    feedback.puts "init-database"
    init_database(dashboard_config)
  end
end
if(not(run_one) or run_one.start_with?('github-sync'))
  feedback.puts "github-sync"
  github_sync(feedback, dashboard_config, client, run_one=='github-sync' ? nil : run_one)
end
if(not(run_one) or run_one=='pull-source')
  feedback.puts "pull-source"
  pull_source(feedback, dashboard_config, client)
end
if(not(run_one) or run_one=='review-source')
  feedback.puts "review-source"
  review_source(feedback, dashboard_config, client)
end
if(not(run_one) or run_one.start_with?('generate-dashboard'))
  feedback.puts "generate-dashboard"

  if(not(run_one) or run_one=='generate-dashboard' or run_one=='generate-dashboard/xml')
    feedback.puts " xml"
    generate_dashboard_xml(feedback, dashboard_config, client)
  end

  if(organizations.length > 1)
    if(not(run_one) or run_one=='generate-dashboard' or run_one=='generate-dashboard/merge')
      feedback.puts " merge"
      merge_dashboard_xml(feedback, dashboard_config)
    end
  end

  if(not(run_one) or run_one=='generate-dashboard' or run_one=='generate-dashboard/teams-xml')
    feedback.puts " teams-xml"
    generate_team_xml(feedback, dashboard_config)
  end

  if(not(run_one) or run_one=='generate-dashboard' or run_one=='generate-dashboard/xslt')
    unless(File.exists?(www_directory))
      Dir.mkdir(www_directory)
    end

    feedback.print " xslt\n  "
    Dir.glob("#{data_directory}/dash-xml/*.xml").each do |inputFile|
      outputFile=File.basename(inputFile, ".xml")

      stylesheet = LibXSLT::XSLT::Stylesheet.new( LibXML::XML::Document.file("generate-dashboard/style/dashboardToHtml.xslt") )
      xml_doc = LibXML::XML::Document.file(inputFile)
      html = stylesheet.apply(xml_doc)

      htmlFile = File.new("#{www_directory}/#{outputFile}.html", 'w')
      htmlFile.write(html)
      htmlFile.close
      feedback.print "."
    end
    feedback.print "\n"

    if(organizations.length > 1)
      feedback.puts " AllOrgs"

      stylesheet = LibXSLT::XSLT::Stylesheet.new( LibXML::XML::Document.file("generate-dashboard/style/dashboardToHtml.xslt") )
      xml_doc = LibXML::XML::Document.file("#{data_directory}/dash-xml/AllOrgs.xml")
      html = stylesheet.apply(xml_doc)

      htmlFile = File.new("#{www_directory}/AllOrgs.html", 'w')
      htmlFile.write(html)
      htmlFile.close
    end

    feedback.puts "\nSee HTML in #{www_directory}/ for dashboard."
  end
end

feedback.puts "Remaining GitHub Calls: #{client.rate_limit.remaining}"
