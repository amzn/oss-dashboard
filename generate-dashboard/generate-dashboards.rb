# Copyright 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# TODO: Figure out how to output team+merged data separately
# Merged is a case of combining the json files neh?
# Teams means having these values for repositories. Tricky.
# Maybe need to redo the team notion into the idea that there are N dashboards 
#   where a dashboard is a set of repositories. Generate each repositories 
#   dash-xml first, then build dashboards out of them.
#   Team + Organization are just special containers. The XSLT can be standard for <repos>
#   and then have customer Overview sections if <teams> or <organization> blocks.
#   Reports are currently separate from <repos>. Need to figure out what would happen 
#   there. repo-reports + issue-reports are easy; merge in with repos. 
#   user-reports less easy as those are more specific to Team/Organizations. 
#   perhaps simplest to ditch user-reports. Everything becomes about repos, not orgs/teams.
# This allows for custom dashboard collections.
# 
# 
# New Dashboard Generation
# 
# Step One
# 
# DONE: Loop over each repository.
# DONE: Generate an XML file for the repository.
# DONE: 	Should contain all Report output of type repo-report or issue-report.
# 		Should also generate all json-data from Reports.
# 		Should generate the hardcoded json-data.
# 		[Perhaps the repoCount chart data is:
# 			2014: Private, 2015: Private, 2016: Public, 2017: Public]
# 	Create/Run XSLT for the repository.
# 
# 
# Step Two
# 
# 	Dashboards. A dashboard is a collection of repositories.
# 	For each dashboard
# 		For each repository in the dashboard
# 			Add the repository XML to a larger dashboard XML
# 	Run XSLT for the Dashboard

require_relative './generate-dashboard-lib'
require 'rexml/document'
include REXML

def generate_tng_repo_xml(context)

  organizations = context.dashboard_config['organizations+logins']
  data_directory = context.dashboard_config['data-directory']

  sync_db = get_db_handle(context.dashboard_config)

  unless(File.exists?("#{data_directory}/dash-xml/"))
    Dir.mkdir("#{data_directory}/dash-xml/")
  end

  # Generate XML for Repo data, including time-indexed metrics and collaborators
  # TODO: How to integrate internal ticketing mapping
  context.feedback.print '  repos '
  repos=sync_db["SELECT id, org, name, homepage, private, fork, has_wiki, language, stars, watchers, forks, created_at, updated_at, pushed_at, size, description FROM repository"]
  repos.each do |repoRow|

    org = repoRow[:org]
    repoName = repoRow[:name]

    unless(File.exists?("#{data_directory}/dash-xml/#{org}/"))
      Dir.mkdir("#{data_directory}/dash-xml/#{org}/")
    end
    repo_xml_file=File.open("#{data_directory}/dash-xml/#{org}/#{repoName}.xml", 'w')

    closedIssueCountRow = sync_db["SELECT COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoName}'"]
    closedIssueCount = closedIssueCountRow.first[:count]
    openIssueCountRow = sync_db["SELECT COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoName}' AND state!='closed'" ]
    openIssueCount = openIssueCountRow.first[:count]
    privateRepo=repoRow[:private]
    isFork=repoRow[:fork]
    hasWiki=repoRow[:has_wiki]
    closedPullRequestCountRow = sync_db["SELECT COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoName}' AND state='closed'"]
    closedPullRequestCount = closedPullRequestCountRow.first[:count]
    openPullRequestCountRow = sync_db["SELECT COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoName}' AND state!='closed'"]
    openPullRequestCount = openPullRequestCountRow.first[:count]
    commitCountRow = sync_db["SELECT COUNT(*) FROM commits WHERE org='#{org}' AND repo='#{repoName}'"]
    commitCount = commitCountRow.first[:count]

    repo_xml_file.puts "  <repo name='#{repoName}' org='#{org}' homepage='#{escape_for_xml(repoRow[:homepage])}' private='#{privateRepo}' fork='#{isFork}' closed_issue_count='#{closedIssueCount}' closed_pr_count='#{closedPullRequestCount}' open_issue_count='#{openIssueCount}' open_pr_count='#{openPullRequestCount}' has_wiki='#{hasWiki}' language='#{repoRow[:language]}' stars='#{repoRow[:stars]}' watchers='#{repoRow[:watchers]}' forks='#{repoRow[:forks]}' created_at='#{repoRow[:created_at]}' updated_at='#{repoRow[:updated_at]}' pushed_at='#{repoRow[:pushed_at]}' size='#{repoRow[:size]}' commit_count='#{commitCount}'>"
    desc = repoRow[:description] ? repoRow[:description].gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;") : repoRow[:description]
    repo_xml_file.puts "    <description>#{desc}</description>"

    collaborators = sync_db["SELECT m.login FROM member m, repository_to_member rtm WHERE rtm.member_id=m.id AND rtm.repo_id=?", repoRow[:id]]

    # TODO: This check is incorrect, needs to check for emptiness in the response, not nil
    if(collaborators)
      repo_xml_file.puts "    <collaborators>"
      collaborators.each do |collaborator|
        repo_xml_file.puts "      <collaborator>#{collaborator[:login]}</collaborator>"
      end
      repo_xml_file.puts "    </collaborators>"
    end

    # Get the issues specifically
    issuesRows = sync_db["SELECT id, item_number, assignee_login, user_login, state, title, body, org, repo, created_at, updated_at, comment_count, pull_request_url, merged_at, closed_at FROM items WHERE org=? AND repo=? AND state='open'", org, repoName]
    repo_xml_file.puts "    <issues count='#{issuesRows.all.length}'>"
    issuesRows.each do |issueRow|
      isPR=(issueRow[:pull_request_url] != nil)
      prText=''
      if(isPR)
        changes=sync_db["SELECT COUNT(filename), SUM(additions) as add , SUM(deletions) as del FROM pull_request_files WHERE pull_request_id=?", issueRow[:id]]
        prText=" prFileCount='#{changes.first[:count]}' prAdditions='#{changes.first[:add]}' prDeletions='#{changes.first[:del]}'"
      end
      # TMP: Replace backspace because of #71 of aws-fluent-plugin-kinesis
      title=issueRow[:title].gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/[\b]/, '')

      age=((Time.now - Time.parse(issueRow[:created_at].to_s)) / (60 * 60 * 24)).round
      # TODO: Add labels as a child of issue.
      repo_xml_file.puts "      <issue id='#{issueRow[:id]}' number='#{issueRow[:item_number]}' user='#{issueRow[:user_login]}' state='#{issueRow[:state]}' created_at='#{issueRow[:created_at]}' age='#{age}' updated_at='#{issueRow[:updated_at]}' pull_request='#{isPR}' comments='#{issueRow[:comment_count]}'#{prText}><title>#{title}</title>"
      labels=sync_db["SELECT l.url, l.name, l.color FROM labels l, item_to_label itl WHERE itl.url=l.url AND item_id=?", issueRow[:id]]
      labels.each do |label|
        labelName=label[:name].gsub(/ /, '&#xa0;')
        repo_xml_file.puts "        <label url=\"#{escape_for_xml(label[:url])}\" color='#{label[:color]}'>#{escape_for_xml(labelName)}</label>"
      end
      repo_xml_file.puts "      </issue>"
    end
    repo_xml_file.puts "    </issues>"

    repo_xml_file.puts "  <release-data>"
    releases=sync_db["SELECT DISTINCT(id), html_url, name, published_at, author FROM releases WHERE org='#{org}' AND repo='#{repoName}' ORDER BY published_at DESC"]
    releases.each do |release|
      repo_xml_file.puts "    <release id='#{release[:id]}' url='#{release[:html_url]}' published_at='#{release[:published_at]}' author='#{release[:author]}'>#{escape_for_xml(release[:name])}</release>"
    end
    repo_xml_file.puts "  </release-data>"

    repo_xml_file.puts "  <traffic-data>"
    views=sync_db["SELECT count, uniques FROM traffic_views_total WHERE org=? AND repo=? ORDER BY recorded_at DESC LIMIT 1", org, repoName].first
    if(views)
      repo_xml_file.puts "    <views count='#{views[:count]}' uniques='#{views[:uniques]}'/>"
    end
    clones=sync_db["SELECT count, uniques FROM traffic_clones_total WHERE org=? AND repo=? ORDER BY recorded_at DESC LIMIT 1", org, repoName].first
    if(clones)
      repo_xml_file.puts "    <clones count='#{clones[:count]}' uniques='#{clones[:uniques]}'/>"
    end
    referrer=sync_db["SELECT referrer, count, uniques FROM traffic_referrers WHERE org=? AND repo=? ORDER BY recorded_at DESC LIMIT 1", org, repoName].first
    if(referrer)
      repo_xml_file.puts "    <referrer count='#{referrer[:count]}' uniques='#{referrer[:uniques]}'>#{referrer[:referrer]}</referrer>"
    end
    repo_xml_file.puts "  </traffic-data>"

    # Copy over the source review reports
    if(File.exists?("#{data_directory}/review-xml/#{org}/#{repoName}.xml"))
      txt=File.read("#{data_directory}/review-xml/#{org}/#{repoName}.xml")
      repo_xml_file.puts txt
    end

    # Copy over the db review reports
    if(File.exists?("#{data_directory}/db-report-xml/#{org}/#{repoName}.xml"))
      txt=File.read("#{data_directory}/db-report-xml/#{org}/#{repoName}.xml")
      repo_xml_file.puts txt
    end

    repo_xml_file.puts "  </repo>"

    context.feedback.print '.'
    repo_xml_file.close
  end

  context.feedback.print "\n"

end

# Get an org's repos as an array of org/repo
def repos_for_org(context,sync_db,  org)
  return sync_db["SELECT org || '/' || name AS name FROM repository WHERE org=?", org].map { |hash| hash[:name] }
end

def repos_for_slug(context, sync_db, slug)
  return sync_db["SELECT r.org || '/' || r.name AS name FROM team_to_repository ttr, repository r, team t WHERE ttr.team_id=t.id AND ttr.repository_id=r.id AND t.slug=?", slug].map { |hash| hash[:name] }
end

# Get a team's repos as an array of org/repo
def repos_for_team(context, sync_db, org_slug)
  return sync_db["SELECT r.org || '/' || r.name AS name FROM team_to_repository ttr, repository r, team t WHERE ttr.team_id=t.id AND ttr.repository_id=r.id AND r.org || '/' || t.slug=?", org_slug].map { |hash| hash[:name] }
end

# Copy over a set of repos' xml files to the output file
def add_repo_xml(context, sync_db, repos, file)
  data_directory = context.dashboard_config['data-directory']
  repos.each do |repoFullName|
    # Copy over the repo xml
    if(File.exists?("#{data_directory}/dash-xml/#{repoFullName}.xml"))
      txt=File.read("#{data_directory}/dash-xml/#{repoFullName}.xml")
      file.puts txt
    end
  end
end

# Get an org's teams as an array of org/slug
def teams_for_org(context, sync_db, org)
  return sync_db["SELECT org || '/' || slug AS org_slug FROM team WHERE org=?", org].map { |hash| hash[:org_slug] }
end

def teams_for_slug(context, sync_db, slug)
  return sync_db["SELECT org || '/' || slug AS org_slug FROM team WHERE slug=?", slug].map { |hash| hash[:org_slug] }
end

def add_org_xml(context, sync_db, org, file)

  # the LIKE provides case insensitive selection
  org_data_row=sync_db["SELECT avatar_url, description, blog, name, location, email, created_at FROM organization WHERE login LIKE ?", org].first
  
  account_type="organization"
  if(context.login?(org))
    account_type="login"
  end

  file.puts " <organization name='#{org}' avatar='#{org_data_row[:avatar_url]}' type='#{account_type}'>"
  unless(org_data_row[:description]=="")
    file.puts "  <description>#{escape_for_xml(org_data_row[:description])}</description>"
  end
  unless(org_data_row[:blog]=="")
    file.puts "  <url>#{org_data_row[:blog]}</url>"
  end
  unless(org_data_row[:name]=="")
    file.puts "  <name>#{org_data_row[:name]}</name>"
  end
  unless(org_data_row[:location]=="")
    file.puts "  <location>#{escape_for_xml(org_data_row[:location])}</location>"
  end
  unless(org_data_row[:email]=="")
    file.puts "  <email>#{org_data_row[:email]}</email>"
  end
  unless(org_data_row[:created_at]=="")
    file.puts "  <created_at>#{org_data_row[:created_at]}</created_at>"
  end

  # Generate XML for Member data
  members=sync_db["SELECT DISTINCT(m.login), u.email as uemail, m.name, m.avatar_url, m.company, m.email as memail FROM organization o JOIN organization_to_member otm ON otm.org_id=o.id JOIN member m ON m.id = otm.member_id LEFT OUTER JOIN users u ON u.login=m.login WHERE o.login=?", org]
  members.each do |memberRow|
    # TODO: Include whether the individual is in ldap
    internalLogin=""
    if(memberRow[:uemail])
      internalLogin=memberRow[:uemail].split('@')[0]
      internalText=" internal='#{internalLogin}' employee_email='#{memberRow[:uemail]}'"
    end
    file.puts "  <member login='#{memberRow[:login]}' avatar_url='#{memberRow[:avatar_url]}' email='#{memberRow[:memail]}'#{internalText}><company>#{escape_for_xml(memberRow[:company])}</company><name>#{memberRow[:name]}</name></member>"
  end

  file.puts " </organization>"
end
  
def add_team_xml(context, sync_db, org_slug, file)

  # Generate XML for Team data if available
  teams=sync_db["SELECT DISTINCT(t.id) as id, t.name, t.slug, t.description, r.org FROM team t, repository r, team_to_repository ttr WHERE t.id=ttr.team_id AND ttr.repository_id=r.id AND r.org || '/' || t.slug=?", org_slug]
  teams.each do |teamRow|
    # TODO: Indicate if a team has read-only access to a repo, not write.
    file.puts "  <team slug='#{teamRow[:slug]}' name='#{escape_for_xml(teamRow[:name])}' org='#{teamRow[:org]}'>"
    desc=teamRow[:description]
    if(desc)
      desc=desc.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
    end
    file.puts "    <description>#{desc}</description>"
  
    # Load the ids for repos team has access to
    repos=sync_db["SELECT r.name FROM team_to_repository ttr, repository r WHERE ttr.team_id=? AND ttr.repository_id=r.id AND r.fork='false'", teamRow[:id]]
    file.puts "    <repos>"
    repos.each do |teamRepoRow|
      file.puts "        <repo>#{teamRepoRow[:name]}</repo>"
    end
    file.puts "    </repos>"
  
    # Load the ids for the members of the team
    members=sync_db["SELECT m.login FROM team_to_member ttm, member m WHERE ttm.team_id=? AND ttm.member_id=m.id", teamRow[:id]]
    file.puts "    <members>"
    members.each do |teamMemberRow|
      file.puts "      <member>#{teamMemberRow[:login]}</member>"
    end
    file.puts "    </members>"
    file.puts "  </team>"
  end
end

def slugs_for_organizations(context, sync_db, organizations)
  slugs=Set.new

  organizations.each do |org|
    slugs.merge(sync_db["SELECT slug FROM team WHERE org=?", org].map { |hash| hash[:slug] })
  end

  return slugs
end

def generate_tng_dashboards(context)

  # Three ways to get sets of repositories
  # 1. Organizations/Logins
  # 2. Teams
  # 3. Custom definition (which can include Teams/Orgs/Logins as well)

  data_directory = context.dashboard_config['data-directory']
  sync_db = get_db_handle(context.dashboard_config)

#  if(context.dashboard_config['organization-dashboards'])
    context.feedback.print '  organization-dashboards '
    organizations = context.dashboard_config['organizations+logins']

    unless(File.exists?("#{data_directory}/dash-xml/"))
      Dir.mkdir("#{data_directory}/dash-xml/")
    end
  
    # First, generate the metadata needed to build navigation
    # Which other orgs form a part of this site?
    metadata=generate_metadata_header(context)
  
    organizations.each do |org|
      generate_organization_dashboard(context, sync_db, org, metadata)
      generate_json_for_dashboard(context, org, repos_for_org(context, sync_db, org))
    end

    context.feedback.print "\n"
#  end

#  if(context.dashboard_config['team-dashboards'])
    context.feedback.print '  team-dashboards '

    organizations = context.dashboard_config['organizations+logins']
    slugs=slugs_for_organizations(context, sync_db, organizations)

    slugs.each do |slug|
      generate_team_dashboard(context, sync_db, slug, metadata)
      generate_json_for_dashboard(context, "team-#{slug}", repos_for_slug(context, sync_db, slug))
    end
    context.feedback.print "\n"
#  end

  # TODO: Implement this
  if(context.dashboard_config['custom-dashboards'])
    context.feedback.print '  custom-dashboards '
    context.feedback.print "\n"
  end

end

def generate_organization_dashboard(context, sync_db, org, metadata)

  data_directory = context.dashboard_config['data-directory']

  org_data=sync_db["SELECT avatar_url FROM organization WHERE login LIKE ?", org]

  unless(org_data.first)
    context.feedback.puts "!"
    return
  end

  dashboard_file=File.open("#{data_directory}/dash-xml/#{org}.xml", 'w')

  dashboard_file.puts "<github-dashdata dashboard='#{org}' includes_private='#{context.private_access?(org)}' hide_private_repositories='#{context.hide_private_repositories?}' logo='#{org_data.first[:avatar_url]}' github_url='#{context.github_url}'>"

  dashboard_file.puts metadata

  add_org_xml(context, sync_db, org, dashboard_file)

  teams=teams_for_org(context, sync_db, org)
  teams.each do |org_slug|
    add_team_xml(context, sync_db, org_slug, dashboard_file)
  end

  repos=repos_for_org(context, sync_db, org)
  add_repo_xml(context, sync_db, repos, dashboard_file)

  dashboard_file.puts "</github-dashdata>"
  dashboard_file.close
  context.feedback.print "."
end

def generate_team_dashboard(context, sync_db, slug, metadata)

  data_directory = context.dashboard_config['data-directory']

  orgs=sync_db["SELECT org FROM team WHERE slug = ?", slug]

  unless(orgs.first)
    context.feedback.puts "!"
    return
  end

  dashboard_file=File.open("#{data_directory}/dash-xml/team-#{slug}.xml", 'w')

  dashboard_file.puts "<github-dashdata dashboard='team-#{slug}' team='true' hide_private_repositories='#{context.hide_private_repositories?}' github_url='#{context.github_url}'>"

  dashboard_file.puts metadata

  orgs.each do |orgRow|
    add_org_xml(context, sync_db, orgRow[:org], dashboard_file)
  end

  teams=teams_for_slug(context, sync_db, slug)
  teams.each do |org_slug|
    add_team_xml(context, sync_db, org_slug, dashboard_file)
  end

  repos=repos_for_slug(context, sync_db, slug)
  add_repo_xml(context, sync_db, repos, dashboard_file)

  dashboard_file.puts "</github-dashdata>"
  dashboard_file.close
  context.feedback.print "."
end

def merge_dashboard_xml_to(context, attribute, xmlfile, title)

  organizations = context.dashboard_config[attribute]
  unless(organizations)
    return
  end

  data_directory = context.dashboard_config['data-directory']

  dashboard_file=File.open("#{data_directory}/dash-xml/#{xmlfile}", 'w')
  # TODO: Don't hard code includes_private
  dashboard_file.puts "<github-dashdata dashboard='#{title}' includes_private='true' github_url='#{context.github_url}'>"

  dashboard_file.puts(generate_metadata_header(context))

  context.feedback.puts " merge: #{title}"

  organizations.each do |org|

    filename="#{data_directory}/dash-xml/#{org}.xml"
    unless(File.exist?(filename))
      next
    end
    xmlfile=File.new(filename)
    begin
      dashboardXml = Document.new(xmlfile)
    end

    dashboardXml.root.each_element("organization") do |child|
      dashboard_file.puts " #{child}"
    end
    # TODO: Need to filter out duplicates if this is used to merge custom dashboards
    dashboardXml.root.each_element("repo") do |child|
      dashboard_file.puts " #{child}"
    end

    xmlfile.close
    context.feedback.puts "  #{org}"
  end

  dashboard_file.puts "</github-dashdata>"

  dashboard_file.close

end
