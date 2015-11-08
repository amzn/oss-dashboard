#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'

class DbReporter

  # intended to be overridden
  # returns strings in xml format
  def db_report(repo, db)
    raise "No db_report(repo, db) function defined by report subclass"
  end
  
end
