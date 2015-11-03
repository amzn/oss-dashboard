require 'rubygems'
require 'octokit'
require 'yaml'

require_relative 'reporter.rb'

# Dashboard configuration
config_file = File.join(File.dirname(__FILE__), "../config-dashboard.yml")
config = YAML.load(File.read(config_file))
dashboard_config = config['dashboard']

organizations = dashboard_config['organizations']
data_directory = dashboard_config['data-directory']
scratch_dir="#{data_directory}/scratch"
reports = dashboard_config['reports']
report_path = dashboard_config['report-path']

# GitHub setup
config_file = File.join(File.dirname(__FILE__), "../config-github.yml")
config = YAML.load(File.read(config_file))
github_config = config['github']

Octokit.auto_paginate = true
client = Octokit::Client.new :access_token => github_config['access_token'], :accept => 'application/vnd.github.moondragon+json' 


# Standard reporters
require_relative 'report_docs.rb'

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

unless(File.exists?("#{data_directory}/review-xml/"))
  Dir.mkdir("#{data_directory}/review-xml/")
end

organizations.each do |owner|
  review_file=File.open("#{data_directory}/review-xml/#{owner}.xml", 'w')

  report="<github-review>\n"
  report << " <organization name='#{owner}'>\n"

  repos = client.organization_repositories(owner)
  repos.each do |repo|
    if repo.fork
      next
    end

    report << "  <repo name='#{repo.name}'>\n"

    reports.each do |reportName|
      clazz = Object.const_get(reportName)
      instance=clazz.new
      report << instance.report(repo, "#{scratch_dir}/#{repo.full_name}").to_s
    end
    
    report << "  </repo>\n"

  end
  report << " </organization>\n"
  report << "</github-review>\n"
  review_file.puts report
end

