#!/usr/bin/env ruby

require_relative 'user_emails.rb'
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

commit_db=SQLite3::Database.new '../db/gh-sync.db'
loadUserTable(commit_db, USER_EMAILS)

