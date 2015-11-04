#!/usr/bin/env ruby

# TODO: This should come from the dashboard_config and be YAML/JSON
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

def sync_user_mapping(dashboard_config, client, sync_db)
  loadUserTable(sync_db, USER_EMAILS)
end

