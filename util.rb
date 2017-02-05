# Copyright (c) 2017, Salesforce.com, Inc. or its affiliates. All Rights Reserved.

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


require 'sequel'

# returns a Sequel handle to specified database
def get_db_handle(config)
  db_config = config[:database.to_s]
  engine    = db_config[:engine.to_s]

  if engine.eql?('postgres')
    require 'pg'
    # TODO ensure that all keys are provided
    user     = ENV['DB_USERNAME'] ? ENV['DB_USERNAME'] : db_config[:username.to_s]
    password = ENV['DB_PASSWORD'] ? ENV['DB_PASSWORD'] : db_config[:password.to_s]
    server   = ENV['DB_SERVER'] ? ENV['DB_SERVER'] : db_config[:server.to_s]
    port     = ENV['DB_PORT'] ? ENV['DB_PORT'] : db_config[:port.to_s]
    database = ENV['DB_DATABSE'] ? ENV['DB_DATABSE'] : db_config[:database.to_s]
    completeDBUrl = ENV['DATABASE_URL'] ? ENV['DATABASE_URL'] : sprintf('postgres://%s:%s@%s:%s/%s', user, password, server, port, database)
    return Sequel.connect(completeDBUrl)
  else
    raise StandardError.new(sprintf('unsupported database engine[%s]', config[:engine]))
  end
end

# TODO: Change this code - it has the side-effect of creating the database rather than just asking if it exists
def db_exists?(config)
  db_config = config[:database.to_s]
  engine    = db_config[:engine.to_s]

  if engine.eql?('postgres')
    dbh = get_db_handle(config)
    begin
      tables = dbh.tables
      return ! tables.empty?
    rescue => e # TODO need to be more specific about which exception we're catching
      puts "Error during db check: #{$!}"
      init_postgres_db(config)
      return false
    end
  end
end

def init_postgres_db(config)
  db_config = config[:database.to_s]
  user     = ENV['DB_USERNAME'] ? ENV['DB_USERNAME'] : db_config[:username.to_s]
  password = ENV['DB_PASSWORD'] ? ENV['DB_PASSWORD'] : db_config[:password.to_s]
  server   = ENV['DB_SERVER'] ? ENV['DB_SERVER'] : db_config[:server.to_s]
  port     = ENV['DB_PORT'] ? ENV['DB_PORT'] : db_config[:port.to_s]
  database = ENV['DB_DATABSE'] ? ENV['DB_DATABSE'] : db_config[:database.to_s]

  puts "Creating db #{database}..."
  begin
    completeDBUrl = ENV['DATABASE_URL'] ? ENV['DATABASE_URL'] : sprintf('postgres://%s:%s@%s:%s/%s', user, password, server, port, 'template1')
    conn=Sequel.connect(completeDBUrl)
    conn.run "CREATE DATABASE #{database}"    # TODO: Can this move to a parameterized execution?
    conn.disconnect
  rescue => e # TODO need to be more specific about which exception we're catching
    puts "Unable to create database, trying createdb command locally"
    `createdb --owner postgres #{database}`
  end
end
