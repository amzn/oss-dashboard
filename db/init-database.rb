# Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def init_database(context)

  data_directory = context.dashboard_config['data-directory']
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

  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_metadata_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_event_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_release_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_commit_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_issue_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_user_schema.sql' ) ) )
  sync_db.execute_batch( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_traffic_schema.sql' ) ) )

  sync_db.close

end

