#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'sqlite3'
require 'date'
require 'yaml'

# TODO: Move this out of a hard coded file and into something the dashboard config provides
require_relative '../user_mapping/user_emails.rb'

def db_open(filename)
  db = SQLite3::Database.new filename
  return db
end

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

def store_organization_members(db, client, org, private)

  # Build a map of the individuals in an org who have 2fa disabled
  disabled_2fa=Hash.new
  if(private)
    client.org_members(org, 'filter' => '2fa_disabled').each do |user|
      disabled_2fa[user.login] = true
    end
  end

  client.organization_members(org).each do |member_obj|
    db.execute("DELETE FROM member WHERE id=?", [member_obj.id])

    employee_email=USER_EMAILS[member_obj.login]
    # in_ldap=invoke ldap plugin...
    if(private == false)
      d_2fa='unknown'
    elsif(disabled_2fa[member_obj.login])
      d_2fa='true'
    else
      d_2fa='false'
    end

    db.execute("INSERT INTO member (id, login, two_factor_disabled, employee_email)
                VALUES(?, ?, ?, ?)", [member_obj.id, member_obj.login, d_2fa, employee_email] )
  end
end


def sync_metadata(dashboard_config, client, sync_db)

  organizations = dashboard_config['organizations']
  data_directory = dashboard_config['data-directory']
  private_access = dashboard_config['private-access']
  unless(private_access)
    private_access = []
  end

  organizations.each do |org_login|
    store_organization(sync_db, client, org_login)
    store_organization_repositories(sync_db, client, org_login)
    store_organization_members(sync_db, client, org_login, private_access.include?(org_login))
    if(private_access.include?(org_login))
      store_organization_teams(sync_db, client, org_login)
    end
  end

end
