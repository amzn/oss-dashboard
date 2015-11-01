#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'date'
require 'yaml'

require_relative 'db_metadata/sync-metadata.rb'
require_relative 'db_commits/sync-commits.rb'
require_relative 'db_events/sync-events.rb'
require_relative 'db_issues/sync-issues.rb'
require_relative 'db_releases/sync-releases.rb'

sync_metadata
sync_commits
sync_events
sync_issues
sync_releases

