#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require_relative 'db_reporter'

class No2faDbReporter < DbReporter

  def db_columns()
    return ['login']
  end

  def db_report(org, sync_db)
    no2fa=sync_db.execute("SELECT DISTINCT(m.login) FROM member m, repository r, team_to_member ttm, team_to_repository ttr WHERE m.two_factor_disabled='false' AND m.id=ttm.member_id AND ttm.team_id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?", [org])
    text = ''
    no2fa.each do |row|
      text << "  <db-reporting type='No2faDbReporter'>#{row[0]}</db-reporting>\n"
    end
    return text
  end

end
