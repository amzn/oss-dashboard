#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require_relative 'db_reporter'

class EmptyDbReporter < DbReporter

  def db_columns()
    return ['repository']
  end

  def db_report(org, sync_db)
    empty=sync_db.execute("SELECT r.name FROM repository r WHERE size=0 AND r.org=?", [org])
    text = ''
    empty.each do |row|
      text << "  <db-reporting type='EmptyDbReporter'>#{row[0]}</db-reporting>\n"
    end
    return text
  end

end
