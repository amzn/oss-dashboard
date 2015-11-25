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
require 'sqlite3'
require 'date'
require 'yaml'

def store_organization(db, client, org_login)
  org=client.organization(org_login)
  
  db.execute("DELETE FROM organization WHERE id=?", [org.id])
  db.execute(
    "INSERT INTO organization (
      login, id, url, avatar_url, description, name, company, blog, location, email, public_repos, public_gists, followers, following, html_url, created_at, type
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [org.login, org.id, org.url, org.avatar_url, org.description, org.name, org.company, org.blog, org.location, org.email, org.public_repos, org.public_gists, org.followers, org.following, org.html_url, org.created_at.to_s, org.type]
    )
    return org
end

def store_organization_teams(db, client, org)
  client.organization_teams(org).each do |team_obj|

    db.execute("DELETE FROM team WHERE id=?", [team_obj.id])
    db.execute(
      "INSERT INTO team (id, name, description) VALUES (?, ?, ?)",
      [team_obj.id, team_obj.name, team_obj.description])

    db.execute("DELETE FROM team_to_repository WHERE team_id=?", [team_obj.id])
    repos=client.team_repositories(team_obj.id)
    repos.each do |repo_obj|
      db.execute("INSERT INTO team_to_repository (team_id, repository_id) VALUES(?, ?)", [team_obj.id, repo_obj.id])
    end
  
    db.execute("DELETE FROM team_to_member WHERE team_id=?", [team_obj.id])
    members=client.team_members(team_obj.id)
    members.each do |member_obj|
      db.execute("INSERT INTO team_to_member (team_id, member_id) VALUES(?, ?)", [team_obj.id, member_obj.id])
    end
  
  end
end

def store_organization_repositories(db, client, org)
  client.organization_repositories(org).each do |repo_obj|
    watchers=client.send('subscribers', "#{org}/#{repo_obj.name}").length

    db.execute("DELETE FROM repository WHERE id=?", [repo_obj.id])

    db.execute("INSERT INTO repository 
      (id, org, name, homepage, fork, private, has_wiki, language, stars, watchers, forks, created_at, updated_at, pushed_at, size, description)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [repo_obj.id, org, repo_obj.name, repo_obj.homepage, repo_obj.fork ? 1 : 0, repo_obj.private ? 1 : 0, repo_obj.has_wiki ? 1 : 0, repo_obj.language, repo_obj.watchers, watchers, repo_obj.forks, repo_obj.created_at.to_s, repo_obj.updated_at.to_s, repo_obj.pushed_at.to_s, repo_obj.size, repo_obj.description])
  end
end

def store_organization_members(db, client, org_obj, private, previous_members)

  # Mapping for this org's member ids
  org_members=Hash.new

  # Build a mapping of the individuals in an org who have 2fa disabled
  disabled_2fa=Hash.new
  if(private)
    client.org_members(org_obj.login, 'filter' => '2fa_disabled').each do |user|
      disabled_2fa[user.login] = true
    end
  end

  db.execute("DELETE FROM organization_to_member WHERE org_id=?", [org_obj.id])
  client.organization_members(org_obj.login).each do |member_obj|
    org_members[member_obj.id]=true
    unless(previous_members[member_obj.id])
      db.execute("DELETE FROM member WHERE id=?", [member_obj.id])

      if(private == false)
        d_2fa='unknown'
      elsif(disabled_2fa[member_obj.login])
        d_2fa='true'
      else
        d_2fa='false'
      end

      db.execute("INSERT INTO member (id, login, two_factor_disabled, avatar_url)
                  VALUES(?, ?, ?, ?)", [member_obj.id, member_obj.login, d_2fa, member_obj.avatar_url] )

      previous_members[member_obj.id]=true
    end

    db.execute("INSERT INTO organization_to_member (org_id, member_id) VALUES(?, ?)", [org_obj.id, member_obj.id])
  end

  # Get collaborators too - no organization API :(
  if(private)
    client.organization_repositories(org_obj.id).each do |repo_obj|
      db.execute("DELETE FROM repository_to_member WHERE org_id=? AND repo_id=?", [org_obj.id, repo_obj.id])
      collaborators=client.collaborators(repo_obj.full_name)
      collaborators.each do |collaborator|
        unless(previous_members[collaborator.id])
          db.execute("DELETE FROM member WHERE id=?", [collaborator.id])
          db.execute("INSERT INTO member (id, login, two_factor_disabled, avatar_url)
                      VALUES(?, ?, ?, ?)", [collaborator.id, collaborator.login, 'unknown', collaborator.avatar_url] )
          previous_members[collaborator.id]=true
        end
        unless(org_members[collaborator.id])
          # This isn't quite accurate. You can be an outside collaborator to a project and also a member. In reality I should be looking for 
          # those who have access to a repository but are not in a Team with access to the repository. This will, for now, highlight the 
          # the real _outside_ collaborators though, which is the initial requirement. 
          db.execute("INSERT INTO repository_to_member (org_id, repo_id, member_id) VALUES(?, ?, ?)", [org_obj.id, repo_obj.id, collaborator.id])
        end
      end
    end
  end
end

def update_member_data(db, client)
    # Select members in the db and update with their latest data
    members=db.execute("SELECT id FROM member")

    members.each do |member|
      memberId=member[0]
      begin
        user=client.user(memberId)
      rescue Octokit::NotFound => msg
        # puts "ERROR: Unavailable to find user with id: #{memberId}"
        next
      end
      db.execute("UPDATE member SET name=?, company=?, email=? WHERE id=?",
                [user.name, user.company, user.email, user.id] )
    end
end


def sync_metadata(feedback, dashboard_config, client, sync_db)

  organizations = dashboard_config['organizations']
  data_directory = dashboard_config['data-directory']
  private_access = dashboard_config['private-access']
  unless(private_access)
    private_access = []
  end
  feedback.puts " metadata"
  previous_members=Hash.new

  organizations.each do |org_login|
    feedback.print "  #{org_login} "
    org=store_organization(sync_db, client, org_login)
    store_organization_repositories(sync_db, client, org_login)
    store_organization_members(sync_db, client, org, private_access.include?(org_login), previous_members)
    if(private_access.include?(org_login))
      store_organization_teams(sync_db, client, org_login)
    end
    feedback.print "\n"
  end

  feedback.print "  :filling-in-member-data"
  update_member_data(sync_db, client)
  feedback.print "\n"

end
