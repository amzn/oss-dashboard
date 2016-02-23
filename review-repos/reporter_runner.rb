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

require_relative 'reporter.rb'

# Standard reporters
require_relative 'report_docs.rb'
require_relative 'report_license.rb'

def get_reporter_instances(dashboard_config)
  reports = dashboard_config['reports']
  report_path = dashboard_config['report-path']

  # Use the report.path to add others
  if(report_path)
    # TODO: List files matching review_* and automatically require all of them.
    #       Create scopes so they don't affect each other?
    # TODO: Alternatively, at least add a filter so it is only loading the requested reporters
    report_path.each do |report_dir|
      if(Dir.exists?(report_dir))
        Dir.glob(File.join(report_dir, 'report_*')).each do |reportFile|
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

def review_source(context)

  organizations = context.dashboard_config['organizations']
  data_directory = context.dashboard_config['data-directory']
  scratch_dir="#{data_directory}/scratch"

  report_instances=get_reporter_instances(context.dashboard_config)
 
  unless(File.exists?("#{data_directory}/review-xml/"))
    Dir.mkdir("#{data_directory}/review-xml/")
  end
 
  organizations.each do |owner|
    context.feedback.print "  #{owner} "
    review_file=File.open("#{data_directory}/review-xml/#{owner}.xml", 'w')
  
    report="<github-review>\n"
    report << " <organization name='#{owner}'>\n"
  
    repos = context.client.organization_repositories(owner)
    repos.each do |repo|
      if repo.fork
        next
      end
      unless File.exists?("#{scratch_dir}/#{repo.full_name}")
        next
      end
  
      report_instances.each do |report_obj|
        report << report_obj.report(repo, "#{scratch_dir}/#{repo.full_name}").to_s
      end

      context.feedback.print '.'
    end
    report << " </organization>\n"
    report << "</github-review>\n"
    review_file.puts report
    review_file.close
    context.feedback.print "\n"
  end
  
end
