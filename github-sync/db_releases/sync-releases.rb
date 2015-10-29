#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'date'
require 'yaml'

require "sqlite3"

  def db_insert_releases(db, org, repo, releases)
    db.execute("BEGIN TRANSACTION");
    releases.each do |release|
        db.execute(
         "DELETE FROM releases WHERE org=? AND repo=? AND id=?", [org, repo, release.id] )

        # Sometimes there is no author. Instead, fill in the data with the first file's uploader
        if(release.author)
            author=release.author.login
        else
            if(release.assets and release.assets[0] and release.assets[0].uploader)
                author=release.assets[0].uploader.login
#                puts "Unable to find an author for #{release.html_url}; using uploader: #{author}"
            else
                author=nil
#                puts "Unable to find an author or uploader for #{release.html_url}"
            end
        end


        db.execute(
         "INSERT INTO releases (
            org, repo, id, html_url, tarball_url, zipball_url, tag_name, name, body, created_at, published_at, author
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
          [ org, repo, release.id, release.html_url, release.tarball_url, release.zipball_url, release.tag_name, release.name, release.body, release.created_at.to_s, release.published_at.to_s, author] )
    end
    db.execute("END TRANSACTION");
  end

# Expectation is that this is for loading old data; the event stream can be used to update the release db
def getAllReleasesForOrg(client, release_db, org)
  client.organization_repositories(org).each do |repo_obj|
    releases=client.releases(repo_obj.full_name)
    db_insert_releases(release_db, org, repo_obj.name, releases)   # Replace existing with these
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

release_db=SQLite3::Database.new(File.join(File.dirname(__FILE__), '../db/gh-sync.db'))

organizations.each do |org|
  getAllReleasesForOrg(client, release_db, org)
end
