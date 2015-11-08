#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require_relative 'db_reporter'

class UnknownMembersDbReporter < DbReporter

  def db_columns()
    return ['login']
  end

  def db_report(org, sync_db)
    unknown=sync_db.execute("SELECT DISTINCT(m.login) FROM member m, repository r, team_to_member ttm, team_to_repository ttr WHERE m.login NOT IN (SELECT login FROM users) AND m.id=ttm.member_id AND ttm.team_id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?", [org])
    text = ''
    unknown.each do |row|
      text << "  <db-reporting type='UnknownMembersDbReporter'>#{row[0]}</db-reporting>\n"
    end
    return text
  end

end
