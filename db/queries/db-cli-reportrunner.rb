#!/usr/bin/env ruby

# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require "sqlite3"
require_relative '../reporting/db_reporter.rb'

db_filename = ARGV[0]
org = ARGV[1]
report_file = ARGV[2]
reporter = ARGV[3]

unless(File.exists?(db_filename))
  puts "Database does not exist: #{db_filename}"
  exit
end

unless(File.exists?(report_file))
  puts "Report file does not exist: #{report_file}"
  exit
end

require "#{report_file}"

# TODO: Check the report_file has the reporter defined in it?
clazz = Object.const_get(reporter)
report_obj=clazz.new

sync_db=SQLite3::Database.new db_filename

report="<github-db-report>\n"
report << " <organization name='#{org}'>\n"
  
# TODO: Passes a nil dashboard-context; will only work for some reports.
report << report_obj.db_report(nil, org, sync_db).to_s

report << " </organization>\n"
report << "</github-db-report>\n"

puts report
  
sync_db.close

