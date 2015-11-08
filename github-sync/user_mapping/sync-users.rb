#!/usr/bin/env ruby

require "sqlite3"

def loadUserTable(db, users)
  db.execute("BEGIN TRANSACTION");
  db.execute("DELETE FROM users")
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

  # both should be executed and provides USER_EMAILS
  # TODO: It should be executed _after_ the user emails are loaded, ie) there should be a function to call
  map_user_script=dashboard_config['map-user-script']
  if(map_user_script)
    if(File.exist?(map_user_script))
      require(map_user_script)
      loadUserTable(sync_db, USER_EMAILS)
    else
      puts "User mapping script not found: #{map_user_script}"
    end
  end
end

