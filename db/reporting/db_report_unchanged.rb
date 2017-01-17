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

require 'rubygems'
require 'yaml'
require_relative 'db_reporter'

class UnchangedDbReporter < DbReporter

  def name()
    return "Unchanged Repositories"
  end

  def report_class()
    return 'repo-report'
  end

  def describe()
    return "This report shows repositories that have not had any changes since the day they were created. "
  end

  def db_columns()
    return [ 'Date', ['repository', 'org/repo'] ]
  end

  def db_report(context, org, sync_db)
    unchanged=sync_db["SELECT r.name, r.created_at FROM repository r WHERE created_at=pushed_at AND r.org=?", [org]]
    text = ''
    unchanged.each do |row|
      text << "  <reporting class='repo-report' repo='#{org}/#{row[0]}' type='UnchangedDbReporter'><field>#{row[1]}</field><field>#{org}/#{row[0]}</field></reporting>\n"
    end
    return text
  end

end
