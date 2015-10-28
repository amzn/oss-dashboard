#!/usr/bin/env ruby

require './user_emails.rb'
require "sqlite3"

  def loadUserTable(db, users)
    db.execute("BEGIN TRANSACTION");
    db.execute("DELETE FROM users")
    # 'git-login'  => 'amazon-login@amazon.com',
    users.each do |login, email|
        db.execute(
         "INSERT INTO users (
            login, email
          )
          VALUES ( ?, ? )",
          [ login, email ] )
    end
    db.execute("END TRANSACTION");
  end

#### MAIN CODE ####

issue_db=SQLite3::Database.new '../db_issues/gh-issues.db'
loadUserTable(issue_db, USER_EMAILS)

event_db=SQLite3::Database.new '../db_events/gh-events.db'
loadUserTable(event_db, USER_EMAILS)

release_db=SQLite3::Database.new '../db_releases/gh-releases.db'
loadUserTable(release_db, USER_EMAILS)

commit_db=SQLite3::Database.new '../db_commits/gh-commits.db'
loadUserTable(commit_db, USER_EMAILS)

