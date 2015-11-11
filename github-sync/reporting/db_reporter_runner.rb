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
require 'octokit'
require 'yaml'

require_relative 'db_reporter.rb'

def run_db_reports(dashboard_config, client, sync_db)
  
  organizations = dashboard_config['organizations']
  data_directory = dashboard_config['data-directory']

  db_reports = dashboard_config['db-reports']
  db_report_path = dashboard_config['db-report-path']

  unless(db_reports)
    return
  end
  
  # Standard reporters
  require_relative 'db_report_unknown_members.rb'
  require_relative 'db_report_no_2fa.rb'
  require_relative 'db_report_wiki_on.rb'
  require_relative 'db_report_empty.rb'
  require_relative 'db_report_unchanged.rb'
 
  # Use the db_report_path to add others
  if(db_report_path)
    # TODO: List files matching review_* and automatically require all of them.
    #       Create scopes so they don't affect each other?
    # TODO: Alternatively, at least add a filter so it is only loading the requested reporters
    db_report_path.each do |db_report_dir|
      if(Dir.exists?(db_report_dir))
        Dir.glob(File.join(db_report_dir, 'db_report_*')).each do |db_reportFile|
          require "#{db_reportFile}"
        end
      end
    end
  end
  
  unless(File.exists?("#{data_directory}/db-report-xml/"))
    Dir.mkdir("#{data_directory}/db-report-xml/")
  end
  
  organizations.each do |org|
    review_file=File.open("#{data_directory}/db-report-xml/#{org}.xml", 'w')
  
    report="<github-db-report>\n"
    report << " <organization name='#{org}'>\n"
  
    db_reports.each do |reportName|
      clazz = Object.const_get(reportName)
      instance=clazz.new
      report << instance.db_report(org, sync_db).to_s
    end

    report << " </organization>\n"
    report << "</github-db-report>\n"
    review_file.puts report
    review_file.close
  end
  
end
