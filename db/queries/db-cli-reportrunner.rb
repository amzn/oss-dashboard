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

require_relative '../reporting/db_reporter.rb'
require_relative '../../util.rb'

config = YAML.load_file(DB_CONFIG)
org = ARGV[0]
report_file = ARGV[1]
reporter = ARGV[2]

if config.nil? || org.nil? || report_file.nil? || ARGV.first.match(/\-+h(?:elp)/)
  puts sprintf('USAGE: %s <db_config_file> <org> <report_file> [reporter]', __FILE__)
  exit 1
end

unless db_exists?(config)
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

sync_db = get_db_handle(config)

report="<github-db-report>\n"
report << " <organization name='#{org}'>\n"
  
# TODO: Passes a nil dashboard-context; will only work for some reports.
report << report_obj.db_report(nil, org, sync_db).to_s

report << " </organization>\n"
report << "</github-db-report>\n"

puts report
  
sync_db.disconnect

