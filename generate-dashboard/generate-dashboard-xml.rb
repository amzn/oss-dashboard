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
require 'sqlite3'
require 'date'
require 'yaml'

require 'rexml/document'
include REXML

require_relative '../review-repos/reporter_runner'
require_relative '../github-sync/reporting/db_reporter_runner'

def escape_for_xml(text)
  return text ? text.gsub(/&/, '&amp;') : text
end

def generate_report_metadata(context, metadata, tag)
  metadata << "  <#{tag}s>\n"
  report_instances=get_reporter_instances(context.dashboard_config)
  report_instances.each do |report_obj|
    if(report_obj.report_class() == tag)
      metadata << "    <report key='#{report_obj.class.name}' name='#{report_obj.name}'><description>#{report_obj.describe}</description></report>\n"
    end
  end
  db_report_instances=get_db_reporter_instances(context.dashboard_config)
  db_report_instances.each do |report_obj|
    if(report_obj.report_class() == tag)
      metadata << "    <report key='#{report_obj.class.name}' name='#{report_obj.name}'><description>#{report_obj.describe}</description>"
      report_obj.db_columns.each do |db_column|
        if(db_column.kind_of?(Array))
          metadata << "<column-type type='#{db_column[1]}'>#{db_column[0]}</column-type>"
        else
          metadata << "<column-type type='text'>#{db_column}</column-type>"
        end
      end
      metadata << "</report>\n"
    end
  end
  metadata << "  </#{tag}s>\n"
end

def generate_metadata_header(context)
  organizations = context.dashboard_config['organizations']
  logins = context.dashboard_config['logins']
  
  metadata = " <metadata>\n"
  metadata << "  <navigation>\n"
  if(organizations)
    if(organizations.length > 1)
      metadata << "    <organization>AllOrgs</organization>\n"
    end
    organizations.each do |org|
      metadata << "    <organization>#{org}</organization>\n"
    end
  end
  if(logins)
    if(logins.length > 1)
      metadata << "    <login>AllLogins</login>\n"
    end
    logins.each do |login|
      metadata << "    <login>#{login}</login>\n"
    end
  end
  metadata << "  </navigation>\n"
  
  # Which User Management Reports are configured?
  generate_report_metadata(context, metadata, 'user-report')
  
  # Which Repo Reports are configured?
  generate_report_metadata(context, metadata, 'repo-report')

  # Which Issue Reports are configured?
  generate_report_metadata(context, metadata, 'issue-report')

  metadata << "  <run-metrics refreshTime='#{context[:START_TIME]}' generationTime='#{DateTime.now}' startRateLimit='#{context[:START_RATE_LIMIT]}' endRateLimit='#{context[:END_RATE_LIMIT]}' usedRateLimit='#{context[:USED_RATE_LIMIT]}'/>\n"
  
  metadata << " </metadata>\n"
  return metadata
end

# Generate a data file for a GitHub organizations.
# It contains the metadata for the organization, and the metrics.
def generate_dashboard_xml(context)
  
  organizations = context.dashboard_config['organizations+logins']
  data_directory = context.dashboard_config['data-directory']
  private_access = context.dashboard_config['private-access']
  unless(private_access)
    private_access = []
  end
  
  sync_db=SQLite3::Database.new(File.join(data_directory, 'db/gh-sync.db'));
  
  unless(File.exists?("#{data_directory}/dash-xml/"))
    Dir.mkdir("#{data_directory}/dash-xml/")
  end
  
  # First, generate the metadata needed to build navigation
  # Which other orgs form a part of this site?
  metadata=generate_metadata_header(context)
  
  organizations.each do |org|
    context.feedback.print "  #{org} "
    dashboard_file=File.open("#{data_directory}/dash-xml/#{org}.xml", 'w')
  
    org_data=sync_db.execute("SELECT avatar_url, description, blog, name, location, email, created_at FROM organization WHERE login=?", [org])

    dashboard_file.puts "<github-dashdata dashboard='#{org}' includes_private='#{private_access.include?(org)}' logo='#{org_data[0][0]}'>"
    dashboard_file.puts metadata

    account_type="organization"
    if(context.login?(org))
      account_type="login"
    end

    dashboard_file.puts " <organization name='#{org}' avatar='#{org_data[0][0]}' type='#{account_type}'>"
    unless(org_data[0][1]=="")
      dashboard_file.puts "  <description>#{escape_for_xml(org_data[0][1])}</description>"
    end
    unless(org_data[0][2]=="")
      dashboard_file.puts "  <url>#{org_data[0][2]}</url>"
    end
    unless(org_data[0][3]=="")
      dashboard_file.puts "  <name>#{org_data[0][3]}</name>"
    end
    unless(org_data[0][4]=="")
      dashboard_file.puts "  <location>#{org_data[0][4]}</location>"
    end
    unless(org_data[0][5]=="")
      dashboard_file.puts "  <email>#{org_data[0][5]}</email>"
    end
    unless(org_data[0][6]=="")
      dashboard_file.puts "  <created_at>#{org_data[0][6]}</created_at>"
    end
  
    # Generate XML for Team data if available
    teams=sync_db.execute("SELECT DISTINCT(t.id), t.name, t.slug, t.description FROM team t, repository r, team_to_repository ttr WHERE t.id=ttr.team_id AND ttr.repository_id=r.id AND r.org=?", [org])
    teams.each do |teamRow|
      # TODO: Indicate if a team has read-only access to a repo, not write.
      dashboard_file.puts "  <team slug='#{teamRow[2]}' name='#{escape_for_xml(teamRow[1])}'>"
      desc=teamRow[3]
      if(desc)
        desc=desc.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
      end
      dashboard_file.puts "    <description>#{desc}</description>"
  
      # Load the ids for repos team has access to
      repos=sync_db.execute("SELECT r.name FROM team_to_repository ttr, repository r WHERE ttr.team_id=? AND ttr.repository_id=r.id AND r.fork=0", [teamRow[0]])
      dashboard_file.puts "    <repos>"
      repos.each do |teamRepoRow|
        dashboard_file.puts "        <repo>#{teamRepoRow[0]}</repo>"
      end
      dashboard_file.puts "    </repos>"
  
      # Load the ids for the members of the team
      members=sync_db.execute("SELECT m.login FROM team_to_member ttm, member m WHERE ttm.team_id=? AND ttm.member_id=m.id", [teamRow[0]])
      dashboard_file.puts "    <members>"
      members.each do |teamMemberRow|
        dashboard_file.puts "      <member>#{teamMemberRow[0]}</member>"
      end
      dashboard_file.puts "    </members>"
      dashboard_file.puts "  </team>"
    end
  
  
    # Generate XML for Repo data, including time-indexed metrics and collaborators
    # TODO: How to integrate internal ticketing mapping
    repos=sync_db.execute("SELECT id, name, homepage, private, fork, has_wiki, language, stars, watchers, forks, created_at, updated_at, pushed_at, size, description FROM repository WHERE org=?", [org])
    repos.each do |repoRow|
      closedIssueCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )[0][0]
      openIssueCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state!='closed'" )[0][0]
      privateRepo=(repoRow[3]==1)
      isFork=(repoRow[4]==1)
      hasWiki=(repoRow[5]==1)
      closedPullRequestCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )[0][0]
      openPullRequestCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state!='closed'" )[0][0]
      commitCount=sync_db.execute( "SELECT COUNT(*) FROM commits WHERE org='#{org}' AND repo='#{repoRow[1]}'")[0][0]
      dashboard_file.puts "  <repo name='#{repoRow[1]}' homepage='#{repoRow[2]}' private='#{privateRepo}' fork='#{isFork}' closed_issue_count='#{closedIssueCount}' closed_pr_count='#{closedPullRequestCount}' open_issue_count='#{openIssueCount}' open_pr_count='#{openPullRequestCount}' has_wiki='#{hasWiki}' language='#{repoRow[6]}' stars='#{repoRow[7]}' watchers='#{repoRow[8]}' forks='#{repoRow[9]}' created_at='#{repoRow[10]}' updated_at='#{repoRow[11]}' pushed_at='#{repoRow[12]}' size='#{repoRow[13]}' commit_count='#{commitCount}'>"
      desc=repoRow[14]?repoRow[14].gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;"):repoRow[14]
      dashboard_file.puts "    <description>#{desc}</description>"

      collaborators=sync_db.execute( "SELECT m.login FROM member m, repository_to_member rtm WHERE rtm.member_id=m.id AND rtm.repo_id=?", [repoRow[0]] )
      # TODO: This check is incorrect, needs to check for emptiness in the response, not nil
      if(collaborators)
        dashboard_file.puts "    <collaborators>"
        collaborators.each do |collaborator|
          dashboard_file.puts "      <collaborator>#{collaborator[0]}</collaborator>"
        end
        dashboard_file.puts "    </collaborators>"
      end
  
  
        # Get the issues specifically
        issues=sync_db.execute("SELECT id, item_number, assignee_login, user_login, state, title, body, org, repo, created_at, updated_at, comment_count, pull_request_url, merged_at, closed_at FROM items WHERE org=? AND repo=? AND state='open'", [org, repoRow[1]])
        dashboard_file.puts "    <issues count='#{issues.length}'>"
        issues.each do |issueRow|
          isPR=(issueRow[12] != nil)
          prText=''
          if(isPR)
            changes=sync_db.execute("SELECT COUNT(filename), SUM(additions), SUM(deletions) FROM pull_request_files WHERE pull_request_id=?", [issueRow[0]])
            prText=" prFileCount='#{changes[0][0]}' prAdditions='#{changes[0][1]}' prDeletions='#{changes[0][2]}'"
          end
          title=issueRow[5].gsub(/&/, "&amp;").gsub(/</, "&lt;")
          age=((Time.now - Time.parse(issueRow[9])) / (60 * 60 * 24)).round
          # TODO: Add labels as a child of issue.
          dashboard_file.puts "      <issue id='#{issueRow[0]}' number='#{issueRow[1]}' user='#{issueRow[3]}' state='#{issueRow[4]}' created_at='#{issueRow[9]}' age='#{age}' updated_at='#{issueRow[10]}' pull_request='#{isPR}' comments='#{issueRow[11]}'#{prText}><title>#{title}</title>"
          labels=sync_db.execute("SELECT l.url, l.name, l.color FROM labels l, item_to_label itl WHERE itl.url=l.url AND item_id=?", [issueRow[0]])
          labels.each do |label|
            labelName=label[1].gsub(/ /, '&#xa0;')
            dashboard_file.puts "        <label url=\"#{label[0]}\" color='#{label[2]}'>#{labelName}</label>"
          end
          dashboard_file.puts "      </issue>"
        end
        dashboard_file.puts "    </issues>"
    
        # Issue + PR Reports
        dashboard_file.puts "  <issue-data id='#{repoRow[1]}'>"
        # Yearly Issues Opened
        openedIssues=sync_db.execute( "SELECT strftime('%Y',created_at) as year, COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state='open' GROUP BY year ORDER BY year DESC" )
        openedIssues.each do |issuecount|
          dashboard_file.puts "    <issues-opened id='#{repoRow[1]}' year='#{issuecount[0]}' count='#{issuecount[1]}'/>"
        end
        closedIssues=sync_db.execute( "SELECT strftime('%Y',closed_at) as year, COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state='closed' GROUP BY year ORDER BY year DESC" )
     closedIssues.each do |issuecount|
          dashboard_file.puts "    <issues-closed id='#{repoRow[1]}' year='#{issuecount[0]}' count='#{issuecount[1]}'/>"
        end
      
        # Yearly Pull Requests 
        openedPrs=sync_db.execute( "SELECT strftime('%Y',created_at) as year, COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state='open' GROUP BY year ORDER BY year DESC" )
        openedPrs.each do |prcount|
          dashboard_file.puts "    <prs-opened id='#{repoRow[1]}' year='#{prcount[0]}' count='#{prcount[1]}'/>"
        end
        closedPrs=sync_db.execute( "SELECT strftime('%Y',closed_at) as year, COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoRow[1]}' AND state='closed' GROUP BY year ORDER BY year DESC" )
        closedPrs.each do |prcount|
          dashboard_file.puts "    <prs-closed id='#{repoRow[1]}' year='#{prcount[0]}' count='#{prcount[1]}'/>"
        end
    
        # Time to Close
        # TODO: Get rid of the copy and paste here
        dashboard_file.puts "    <age-count>"
        # 1 hour  = 0.0417
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) < 0.0417 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='1 hour'>#{ageCount[0][0]}</issue-count>"
        # 3 hours = 0.125
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 0.0417 AND julianday(closed_at) - julianday(created_at) <= 0.125 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='3 hours'>#{ageCount[0][0]}</issue-count>"
        # 9 hours = 0.375
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 0.125 AND julianday(closed_at) - julianday(created_at) <= 0.375 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='9 hours'>#{ageCount[0][0]}</issue-count>"
        # 1 day
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 0.375 AND julianday(closed_at) - julianday(created_at) <= 1 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='1 day'>#{ageCount[0][0]}</issue-count>"
        # 7 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 1 AND julianday(closed_at) - julianday(created_at) <= 7 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='1 week'>#{ageCount[0][0]}</issue-count>"
        # 30 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 7 AND julianday(closed_at) - julianday(created_at) <= 30 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='1 month'>#{ageCount[0][0]}</issue-count>"
        # 90 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 30 AND julianday(closed_at) - julianday(created_at) <= 90 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='1 quarter'>#{ageCount[0][0]}</issue-count>"
        # 355 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 90 AND julianday(closed_at) - julianday(created_at) <= 365 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='1 year'>#{ageCount[0][0]}</issue-count>"
        # over a year
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM issues WHERE julianday(closed_at) - julianday(created_at) > 365 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <issue-count age='over 1 year'>#{ageCount[0][0]}</issue-count>"
        # REPEATING FOR PRs
        # 1 hour  = 0.0417
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) < 0.0417 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='1 hour'>#{ageCount[0][0]}</pr-count>"
        # 3 hours = 0.125
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 0.0417 AND julianday(closed_at) - julianday(created_at) <= 0.125 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='3 hours'>#{ageCount[0][0]}</pr-count>"
        # 9 hours = 0.375
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 0.125 AND julianday(closed_at) - julianday(created_at) <= 0.375 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='9 hours'>#{ageCount[0][0]}</pr-count>"
        # 1 day
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 0.375 AND julianday(closed_at) - julianday(created_at) <= 1 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='1 day'>#{ageCount[0][0]}</pr-count>"
        # 7 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 1 AND julianday(closed_at) - julianday(created_at) <= 7 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='1 week'>#{ageCount[0][0]}</pr-count>"
        # 30 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 7 AND julianday(closed_at) - julianday(created_at) <= 30 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='1 month'>#{ageCount[0][0]}</pr-count>"
        # 90 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 30 AND julianday(closed_at) - julianday(created_at) <= 90 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='1 quarter'>#{ageCount[0][0]}</pr-count>"
        # 355 days
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 90 AND julianday(closed_at) - julianday(created_at) <= 365 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='1 year'>#{ageCount[0][0]}</pr-count>"
        # over a year
        ageCount=sync_db.execute( "SELECT COUNT(*) FROM pull_requests WHERE julianday(closed_at) - julianday(created_at) > 365 AND org='#{org}' AND repo='#{repoRow[1]}' AND state='closed'" )
        dashboard_file.puts "      <pr-count age='over 1 year'>#{ageCount[0][0]}</pr-count>"
        dashboard_file.puts "    </age-count>"

        projectIssueCount=sync_db.execute( "SELECT COUNT(DISTINCT(i.id)) FROM issues i LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN organization o ON i.org=o.login LEFT OUTER JOIN member m ON otm.member_id=m.id WHERE i.org=? AND i.repo=? AND m.login=i.user_login", [org, repoRow[1]] )
        communityIssueCount=sync_db.execute( "SELECT COUNT(DISTINCT(i.id)) FROM issues i LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN organization o ON i.org=o.login WHERE i.org=? AND i.repo=? AND i.user_login NOT IN (SELECT m.login FROM member m)", [org, repoRow[1]] )
        projectPrCount=sync_db.execute( "SELECT COUNT(DISTINCT(pr.id)) FROM pull_requests pr LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN organization o ON pr.org=o.login LEFT OUTER JOIN member m ON otm.member_id=m.id WHERE pr.org=? AND pr.repo=? AND m.login=pr.user_login", [org, repoRow[1]] )
        communityPrCount=sync_db.execute( "SELECT COUNT(DISTINCT(pr.id)) FROM pull_requests pr LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN organization o ON pr.org=o.login WHERE pr.org=? AND pr.repo=? AND pr.user_login NOT IN (SELECT m.login FROM member m)", [org, repoRow[1]] )

        dashboard_file.puts "    <community-balance>"
        dashboard_file.puts "      <issue-count type='community'>#{communityIssueCount[0][0]}</issue-count>"
        dashboard_file.puts "      <issue-count type='project'>#{projectIssueCount[0][0]}</issue-count>"
        dashboard_file.puts "      <pr-count type='community'>#{communityPrCount[0][0]}</pr-count>"
        dashboard_file.puts "      <pr-count type='project'>#{projectPrCount[0][0]}</pr-count>"
        dashboard_file.puts "    </community-balance>"
    
        dashboard_file.puts "  </issue-data>"
    
        dashboard_file.puts "  <release-data>"
        releases=sync_db.execute( "SELECT DISTINCT(id), html_url, name, published_at, author FROM releases WHERE org='#{org}' AND repo='#{repoRow[1]}' ORDER BY published_at DESC" )
        releases.each do |release|
          dashboard_file.puts "    <release id='#{release[0]}' url='#{release[1]}' published_at='#{release[3]}' author='#{release[4]}'>#{escape_for_xml(release[2])}</release>"
        end
        dashboard_file.puts "  </release-data>"
    
    
      dashboard_file.puts "  </repo>"
    end
  
    # Generate XML for Member data
    members=sync_db.execute("SELECT DISTINCT(m.login), m.two_factor_disabled, u.email, m.name, m.avatar_url, m.company, m.email FROM member m, organization o, organization_to_member otm LEFT OUTER JOIN users u ON m.login=u.login WHERE m.id=otm.member_id AND otm.org_id=o.id AND o.login=?", [org])
    members.each do |memberRow|  
      # TODO: Include whether the individual is in ldap
      internalLogin=""
      if(memberRow[2])
        internalLogin=memberRow[2].split('@')[0]
        internalText=" internal='#{internalLogin}' employee_email='#{memberRow[2]}'"
      end
      dashboard_file.puts "  <member login='#{memberRow[0]}' avatar_url='#{memberRow[4]}' email='#{memberRow[6]}' disabled_2fa='#{memberRow[1]}'#{internalText}><company>#{escape_for_xml(memberRow[5])}</company><name>#{memberRow[3]}</name></member>"
    end
  
    # Copy the review xml into the dashboard xml
    # TODO: This is clunky, but simpler than having xslt talk to more than one file at a time. Replace this, possibly along with XSLT.
    #       Quite possible that there's no need for the review xml file to be separate in the first place.
    dashboard_file.puts " <reports>"
    if(File.exists?("#{data_directory}/review-xml/#{org}.xml"))
      xmlfile=File.new("#{data_directory}/review-xml/#{org}.xml")
      begin
        dashboardXml = Document.new(xmlfile)
      end
  
      dashboardXml.root.each_element("organization/reporting") do |child|
        dashboard_file.puts " #{child}"
      end
      dashboardXml.root.each_element("organization/license") do |child|
        dashboard_file.puts " #{child}"
      end
  
      xmlfile.close
    end
    if(File.exists?("#{data_directory}/db-report-xml/#{org}.xml"))
      xmlfile=File.new("#{data_directory}/db-report-xml/#{org}.xml")
      begin
        dashboardXml = Document.new(xmlfile)
      end
  
      dashboardXml.root.each_element("organization/reporting") do |child|
        dashboard_file.puts " #{child}"
      end
      dashboardXml.root.each_element("organization/license") do |child|
        dashboard_file.puts " #{child}"
      end
  
      xmlfile.close
    end
    dashboard_file.puts " </reports>"
  
    dashboard_file.puts " </organization>"
    dashboard_file.puts "</github-dashdata>"
    
    dashboard_file.close
    context.feedback.print "\n"
  end

end

def merge_dashboard_xml(context)
  merge_dashboard_xml_to(context, 'logins', 'AllLogins.xml', 'All Logins')
  merge_dashboard_xml_to(context, 'organizations', 'AllOrgs.xml', 'All Organizations')
  merge_dashboard_xml_to(context, 'organizations+logins', 'AllAccounts.xml', 'All Accounts')
end

def merge_dashboard_xml_to(context, attribute, xmlfile, title)

  organizations = context.dashboard_config[attribute]
  unless(organizations)
    return
  end

  data_directory = context.dashboard_config['data-directory']

  dashboard_file=File.open("#{data_directory}/dash-xml/#{xmlfile}", 'w')
  # TODO: Don't hard code includes_private
  dashboard_file.puts "<github-dashdata dashboard='#{title}' includes_private='true'>"

  dashboard_file.puts(generate_metadata_header(context))

  organizations.each do |org|

    xmlfile=File.new("#{data_directory}/dash-xml/#{org}.xml")
    begin
      dashboardXml = Document.new(xmlfile)
    end

    dashboardXml.root.each_element("organization") do |child|
      dashboard_file.puts " #{child}"
    end

    xmlfile.close
    context.feedback.puts "  #{org}"
  end

  dashboard_file.puts "</github-dashdata>"

  dashboard_file.close

end

def generate_team_xml(context)

  organizations = context.dashboard_config['organizations+logins']
  data_directory = context.dashboard_config['data-directory']

  if(organizations.length > 1)
    xmlfile=File.new("#{data_directory}/dash-xml/AllOrgs.xml")
  else
    xmlfile=File.new("#{data_directory}/dash-xml/#{organizations[0]}.xml")
  end
  begin
    dashboardXml = Document.new(xmlfile)
  end

  # Copy the metadata from AllOrgs
  header=dashboardXml.root.elements['metadata'].to_s

  # Loop over each unique team
  teams=Set.new
  team_headers=Set.new
  dashboardXml.root.elements.each('organization') do |org|
    org.elements.each('team') do |team|
      teams << [team.attributes['slug'], team.attributes['name']]
      team_headers << "<team name='#{escape_for_xml(team.attributes['name'])}' slug='#{team.attributes['slug']}'/>"
    end
  end
  teams.delete('owners')   # why not working?
  header.insert(header.index(%r{</navigation>}), team_headers.to_a.join("\n    "))

  teams.each do |team, teamname|
    context.feedback.print "  #{team} "

    path="#{data_directory}/dash-xml/team-#{team}.xml"
    f = open(path, 'w')

    f.puts "<github-dashdata dashboard='#{escape_for_xml(teamname)}' team='true'>"
    f.puts header

    # For team, find organizations it appears in
    XPath.each(dashboardXml.root, "organization[team/@slug='#{team}']") do |node|
      org=node.attributes['name']
      teamnode=XPath.first(node, "team[@slug='#{team}']")
      org_clone=node.deep_clone
      report_clone=org_clone.elements['reports'].clone   # shallow clone

      # remove all teams, repos, reports and members
      org_clone.elements.delete_all('team')
      org_clone.elements.delete_all('repo')   # tmp
      org_clone.elements.delete_all('reports')   # tmp
      org_clone.elements.delete_all('member')   # tmp

      # add back the team we're talking about
      org_clone.add(teamnode.deep_clone)

      # For each member of the team
      teamnode.each_element('members/member') do |member|
        # Copy member data
        membernode=XPath.first(node, "member[@login='#{member.text}']")
        if(membernode)
          org_clone.add(membernode.deep_clone)
        end
      end

      # For each repo the team has access to
      teamnode.each_element('repos/repo') do |repo|
        # Copy repo data
        reponode=XPath.first(node, "repo[@name='#{repo.text}']")
        if(reponode)
          org_clone.add(reponode.deep_clone)
        end
      end

      memberReportNodes=XPath.match(dashboardXml.root, "organization[@name='#{org}']/reports/reporting[@class='user-report']")

      # Copy member reports
      teamnode.elements.each("members/member") do |teammember|
        login=teammember.text
        # We want to output the member section for this login
        memberReportNodes.each do |node|
          if(node.text==login)
            report_clone.add(node.deep_clone)
          end
        end
      end

      repoReportNodes=XPath.match(dashboardXml.root, "organization[@name='#{org}']/reports/reporting[@class='repo-report']")
      issueReportNodes=XPath.match(dashboardXml.root, "organization[@name='#{org}']/reports/reporting[@class='issue-report']")
      licenseNodes=XPath.match(dashboardXml.root, "organization[@name='#{org}']/reports/license']")

      # Copy repo/issue/license reports
      teamnode.elements.each("repos/repo") do |teamrepo|
        id=teamrepo.text
        orgrepo="#{org}/#{id}"
        # We want to output the repo section for this id
        licenseNodes.each do |node|
          if(node and node.attributes['repo']==orgrepo)
            report_clone.add(node.deep_clone)
          end
        end
        repoReportNodes.each do |node|
          if(node and node.attributes['repo']==orgrepo)
            report_clone.add(node.deep_clone)
          end
        end
        issueReportNodes.each do |node|
          if(node and node.attributes['repo']==orgrepo)
            report_clone.add(node.deep_clone)
          end
        end
      end

      org_clone.add(report_clone)

      f.puts org_clone
    end
    f.puts "</github-dashdata>"

    f.close
    context.feedback.print "\n"
  end
  context.feedback.print "\n"
  xmlfile.close
end
