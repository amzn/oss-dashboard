#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require_relative 'db_reporter'

class WikiOnDbReporter < DbReporter

  def db_columns()
    return ['repository']
  end

  def db_report(org, sync_db)
    wikiOn=sync_db.execute("SELECT r.org || '/' || r.name FROM repository r WHERE has_wiki='1' AND r.org=?", [org])
    text = ''
    wikiOn.each do |row|
      text << "  <db-reporting type='WikiOnDbReporter'>#{row[0]}</db-reporting>\n"
    end
    return text
  end

end
