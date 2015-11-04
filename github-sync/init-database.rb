#!/usr/bin/env ruby

def init_database(dashboard_config)

  data_directory = dashboard_config['data-directory']
  db_directory="#{data_directory}/db"
  db_filename=File.join(db_directory, 'gh-sync.db');

  unless(File.exist?(db_directory))
    Dir.mkdir(db_directory)
  end

  if(File.exist?(db_filename))
    # Don't init over the top of an existing database
    puts "ERROR: db exists"
    return
  end

  sync_db=SQLite3::Database.new(db_filename);

  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'db_metadata', 'db_metadata_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'db_events', 'db_event_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'db_releases', 'db_release_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'db_commits', 'db_commit_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'db_issues', 'db_issue_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'user_mapping', 'db_user_schema.sql' ) ) )

end

