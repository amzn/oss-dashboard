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

require_relative '../util.rb'

def init_database(context)

  if db_exists?(context.dashboard_config)
    # Don't init over the top of an existing database
    puts "ERROR: Will not initialize over the top of an existing database. Please remove the database if reset is desired. "
    return
  end

  sync_db = get_db_handle(context.dashboard_config)

  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_metadata_schema.sql' ) ) )
  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_event_schema.sql' ) ) )
  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_release_schema.sql' ) ) )
  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_commit_schema.sql' ) ) )
  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_issue_schema.sql' ) ) )
  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_user_schema.sql' ) ) )
  sync_db.run( File.read( File.join( File.dirname(__FILE__), 'schemas', 'db_traffic_schema.sql' ) ) )

  sync_db.disconnect

end

