#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'yaml'

# TODO: Need to use the GitHub API to check the code out, or at the least the private code
# WORKAROUND: Until then, pass in --private and enter credentials or setup SSH key

# Dashboard configuration
config_file = File.join(File.dirname(__FILE__), "../config-dashboard.yml")
config = YAML.load(File.read(config_file))
dashboard_config = config['dashboard']

organizations = dashboard_config['organizations']
data_directory = dashboard_config['data-directory']
DIR="#{data_directory}/scratch"
unless(File.exist?(DIR))
  Dir.mkdir(DIR)
end

# GitHub setup
config_file = File.join(File.dirname(__FILE__), "../config-github.yml")
config = YAML.load(File.read(config_file))
github_config = config['github']

Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => github_config['access_token'], :accept => 'application/vnd.github.moondragon+json' 

private=false
if(ARGV)
  privateMode = (ARGV[0] == '--private')
end

organizations.each do |owner|

    unless(File.exist?("#{DIR}/#{owner}"))
        Dir.mkdir("#{DIR}/#{owner}")
    end
    
    repos = client.organization_repositories(owner)
    repos.each do |repo|
      if repo.fork
        next
      end
      if(privateMode == false and repo.private == true)
        next
      end
      if(privateMode == true and repo.private == false)
        next
      end
      
      repodir="#{DIR}/#{owner}/#{repo.name}"

      # Checkout or update - use other script if repo.private
        unless(File.exist?(repodir))
          `git clone -q --depth 1 https://github.com/#{owner}/#{repo.name}.git #{repodir}`
        else
           # Git 1.8.5 solution
           #   `git -C #{repodir} pull -q`
           Dir.chdir(repodir) do
#             `git pull -q`
# Hoping fetch and reset will work better than pulling
             remote=`cat .git/config | grep 'remote = ' | sed 's/^.*remote = //'`.strip
             branch=`cat .git/config | grep 'merge = ' | sed 's/^.*merge = refs\\\/heads\\\///'`.strip
             `git fetch -q && git reset -q --hard #{remote}/#{branch}`
         end
      end
    end

end
