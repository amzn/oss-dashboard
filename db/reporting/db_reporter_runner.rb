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

# Standard reporters
require_relative 'db_report_unknown_members.rb'
require_relative 'db_report_left_employment.rb'
require_relative 'db_report_unknown_collaborators.rb'
require_relative 'db_report_no_2fa.rb'
require_relative 'db_report_wiki_on.rb'
require_relative 'db_report_team_empty.rb'
require_relative 'db_report_empty.rb'
require_relative 'db_report_unchanged.rb'
require_relative 'db_report_issues_no_comments.rb'
require_relative 'db_report_prs_no_comments.rb'
require_relative 'db_report_repo_unowned.rb'
require_relative 'db_report_labels.rb'
 
# TODO: Consider merging this code with the similar review-source function
def get_db_reporter_instances(dashboard_config)
  reports = dashboard_config['db-reports']
  report_path = dashboard_config['db-report-path']

  # Use the report.path to add others
  if(report_path)
    # TODO: List files matching review_* and automatically require all of them.
    #       Create scopes so they don't affect each other?
    # TODO: Alternatively, at least add a filter so it is only loading the requested reporters
    report_path.each do |report_dir|
      if(Dir.exists?(report_dir))
        Dir.glob(File.join(report_dir, 'db_report_*')).each do |reportFile|
          require "#{reportFile}"
        end
      end
    end
  end

  report_instances=[]
  reports.each do |reportName|
    clazz = Object.const_get(reportName)
    report_instances<<clazz.new
  end
  return report_instances
end

def run_db_reports(context, sync_db)
  
  owners = context.dashboard_config['organizations+logins']
  data_directory = context.dashboard_config['data-directory']

  report_instances=get_db_reporter_instances(context.dashboard_config)

  unless(File.exists?("#{data_directory}/db-report-xml/"))
    Dir.mkdir("#{data_directory}/db-report-xml/")
  end

  context.feedback.puts " reporting"
  
  owners.each do |org|
    context.feedback.print "  #{org} "
    review_file=File.open("#{data_directory}/db-report-xml/#{org}.xml", 'w')
  
    report="<github-db-report>\n"
    report << " <organization name='#{org}'>\n"
  
    report_instances.each do |report_obj|
      report << report_obj.db_report(context, org, sync_db).to_s
      context.feedback.print '.'
    end

    report << " </organization>\n"
    report << "</github-db-report>\n"
    review_file.puts report
    review_file.close
    context.feedback.print "\n"
  end
  
end
