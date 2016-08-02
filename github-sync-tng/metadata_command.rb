# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'octokit'
require 'sqlite3'
require 'date'

require_relative 'base_command'

# [GitHub Client Calls = 1]
#   1 call needed to get org object for the org_id
class SyncMetadataCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_metadata(queue, params[0], params[1])
  end

  def sync_metadata(queue, context, sync_db)
  
    owners = context.dashboard_config['organizations+logins']
    data_directory = context.dashboard_config['data-directory']
    private_access = context.dashboard_config['private-access']
    unless(private_access)
      private_access = []
    end
    context.feedback.puts " metadata"
  
    owners.each do |org_login|
      # Repository access blocked (Octokit::ClientError)
      context.feedback.print "  #{org_login} "

      queue.push(SyncOrgMDCommand.new( { 'org' => org_login } ) )
      queue.push(SyncOrgReposMDCommand.new( { 'org' => org_login } ) )
      unless(context.login?(org_login))
        # Get org object so we have its id
        org_obj=context.client.organization(org_login)
        # TODO: Given we have the org, could just go ahead and store it rather than having SyncOrgMD

        queue.push(SyncOrgMembersMDCommand.new( { 'org' => org_login, 'private' => private_access, 'org_id' => org_obj.id } ) )

        if(private_access.include?(org_login))
          queue.push(SyncOrgTeamsMDCommand.new( { 'org' => org_login } ) )
        end

        # TODO: Need to get collaborators for personal repositories too
        if(private_access.include?(org_login))
          queue.push(SyncOrgCollaboratorsMDCommand.new( { 'org' => org_login, 'org_id' => org_obj.id } ) )
        end
      end

      context.feedback.print "\n"
    end
  
    context.feedback.print " members"
    queue.push(SyncMembersMDCommand.new( Hash.new ) )
    context.feedback.print "\n"
  
  end
end

## MOVE TO A STORE_LIBRARY FROM HERE

# TODO: BUG - By moving the DELETE statements into the procedure functions, orgs are not getting cleaned up for 
#             data that has been removed. 
#             Need to create a new command that pulls the various data and compares to the database, cleaning 
#             out anything that is no longer relevant.

####     def clear_organization(db, org_login)
####       queries = [
####         "DELETE FROM team_to_member WHERE team_id IN (SELECT id FROM team WHERE org=?)",
####         "DELETE FROM organization_to_member WHERE org_id IN (SELECT id FROM organization WHERE login=?)",
####         "DELETE FROM team_to_repository WHERE repository_id IN (SELECT id FROM repository WHERE org=?)",
####         "DELETE FROM repository_to_member WHERE org_id IN (SELECT id FROM organization WHERE login=?)",
####         "DELETE FROM team WHERE org=?",
####         "DELETE FROM repository WHERE org=?",
####         "DELETE FROM organization WHERE org=?"
####       ]
####     
####       queries.each do |query|
####         db.execute(query, [org_login])
####       end
####     end



# [GitHub Client Calls = 1]
class SyncOrgMDCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]
    org_login=@args['org']

    if(context.login?(org_login))
      org=context.client.user(org_login)
    else
      org=context.client.organization(org_login)
    end

    store_organization(sync_db, org)
  end

  def store_organization(db, gh_org)
    db.execute("BEGIN TRANSACTION")
    db.execute("DELETE FROM organization WHERE login=?", gh_org.login)
    db.execute(
      "INSERT INTO organization (
        login, id, url, avatar_url, description, name, company, blog, location, email, public_repos, public_gists, followers, following, html_url, created_at, type
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [gh_org.login, gh_org.id, gh_org.url, gh_org.avatar_url, gh_org.description, gh_org.name, gh_org.company, gh_org.blog, gh_org.location, gh_org.email, gh_org.public_repos, gh_org.public_gists, gh_org.followers, gh_org.following, gh_org.html_url, gh_org.created_at.to_s, gh_org.type]
      )
    db.execute("COMMIT")
  end

end

# [GitHub Client Calls = 1 + 2 x COUNT(REPOS)]
#   1 call to get the teams
#   N (per team repo) calls to get a team's repos
#   N (per team members) calls to get a team's members
class SyncOrgTeamsMDCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]
    org=@args['org']

    store_organization_teams(sync_db, context.client, org)

  end

  def store_organization_teams(db, client, org)
    client.organization_teams(org).each do |team_obj|
      db.execute("BEGIN TRANSACTION")
  
      db.execute("DELETE FROM team WHERE id=?", team_obj.id)
      db.execute(
        "INSERT INTO team (id, org, name, slug, description) VALUES (?, ?, ?, ?, ?)",
        [team_obj.id, org, team_obj.name, team_obj.slug, team_obj.description])
  
      repos=client.team_repositories(team_obj.id)
      db.execute("DELETE FROM team_to_repository WHERE team_id=?", team_obj.id)
      repos.each do |repo_obj|
        db.execute("INSERT INTO team_to_repository (team_id, repository_id) VALUES(?, ?)", [team_obj.id, repo_obj.id])
      end
    
      members=client.team_members(team_obj.id)
      db.execute("DELETE FROM team_to_member WHERE team_id=?", team_obj.id)
      members.each do |member_obj|
        db.execute("INSERT INTO team_to_member (team_id, member_id) VALUES(?, ?)", [team_obj.id, member_obj.id])
      end

      db.execute("COMMIT")
    end
  end
end
    

# [GitHub Client Calls = 1 + COUNT(REPOS)]
#   Lack of 'subscribers', aka watchers, in API means making an additional call per repo
class SyncOrgReposMDCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]
    org=@args['org']

    if(context.login?(org))
      repos=context.client.repositories(org)
    else
      repos=context.client.organization_repositories(org)
    end

    repos.each do |repo_obj|
      begin # Repository access blocked (Octokit::ClientError)
        watchers=context.client.send('subscribers', "#{org}/#{repo_obj.name}").length
        store_organization_repositories(context, sync_db, org, watchers, repo_obj)
      rescue Octokit::ClientError
        context.feedback.print "!#{$!}!"
      end
    end
  end

  def store_organization_repositories(context, db, org, watchers, repo_obj)

    db.execute("BEGIN TRANSACTION")
    db.execute("DELETE FROM repository WHERE id=?", repo_obj.id)
    db.execute("INSERT INTO repository 
        (id, org, name, homepage, fork, private, has_wiki, language, stars, watchers, forks, created_at, updated_at, pushed_at, size, description)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [repo_obj.id, org, repo_obj.name, repo_obj.homepage, repo_obj.fork ? 1 : 0, repo_obj.private ? 1 : 0, repo_obj.has_wiki ? 1 : 0, repo_obj.language, repo_obj.watchers, watchers, repo_obj.forks, repo_obj.created_at.to_s, repo_obj.updated_at.to_s, repo_obj.pushed_at.to_s, repo_obj.size, repo_obj.description])
    db.execute("COMMIT")
  end

end

# [GitHub Client Calls = 3]
#   1 call needed to get the 2fa disable status
#   1 call to get the members
class SyncOrgMembersMDCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]
    org=@args['org']
    org_id=@args['org_id']
    private=@args['private']

    store_organization_members(sync_db, context.client, org, org_id, private)
  end

  # TODO: Get the client parameter out of this API and move to a Library file
  def store_organization_members(db, client, org, org_id, private)
  
    # Build a mapping of the individuals in an org who have 2fa disabled
    disabled_2fa=Hash.new
    if(private)
      client.org_members(org, 'filter' => '2fa_disabled').each do |user|
        disabled_2fa[user.login] = true
      end
    end
  
    client.organization_members(org).each do |member_obj|
      db.execute("BEGIN TRANSACTION")
      member_found=db.execute("SELECT id FROM member WHERE id=?", [member_obj.id])
      
      if(private == false)
        d_2fa='unknown'
      elsif(disabled_2fa[member_obj.login])
        d_2fa='true'
      else
        d_2fa='false'
      end
 
      if(member_found.length > 0)
         db.execute("UPDATE member SET login=?, two_factor_disabled=?, avatar_url=? WHERE id=?",
                    [member_obj.login, d_2fa, member_obj.avatar_url, member_obj.id] )
      else
         db.execute("INSERT INTO member (id, login, two_factor_disabled, avatar_url)
                    VALUES(?, ?, ?, ?)", [member_obj.id, member_obj.login, d_2fa, member_obj.avatar_url] )
      end


      db.execute("DELETE FROM organization_to_member WHERE org_id =? AND member_id=?", [org_id, member_obj.id])
      db.execute("INSERT INTO organization_to_member (org_id, member_id) VALUES(?, ?)", [org_id, member_obj.id])
      db.execute("COMMIT")
    end
  end
  
end


# [GitHub Client Calls = 1 + COUNT(Repo)]
#   1 call to get the repositories
#   1 call per repository to get the collaborators
class SyncOrgCollaboratorsMDCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]
    org=@args['org']
    org_id=@args['org_id']

    store_organization_collaborators(sync_db, context.client, org, org_id)
  end

  def store_organization_collaborators(db, client, org, org_id)

    owners=client.org_members(org, 'role' => 'admin').map { |user| user.login }

    # Get collaborators too - no organization API :(
    client.organization_repositories(org).each do |repo_obj|
      collaborators=client.collaborators(repo_obj.full_name)
      collaborators.each do |collaborator|

        if(owners.include?(collaborator.login))
          next
        end

        db.execute("BEGIN TRANSACTION")

        member_found=db.execute("SELECT id FROM member WHERE id=?", [collaborator.id])
        if(member_found.length == 0)
          db.execute("DELETE FROM member WHERE id=?", [collaborator.id])
          db.execute("INSERT INTO member (id, login, two_factor_disabled, avatar_url)
                      VALUES(?, ?, ?, ?)", [collaborator.id, collaborator.login, 'unknown', collaborator.avatar_url] )
        end
        member_of_repo=db.execute("SELECT COUNT(*) FROM team_to_member ttm, team_to_repository ttr, repository r WHERE ttm.team_id=ttr.team_id AND ttr.repository_id=? AND ttm.member_id=?", [repo_obj.id, collaborator.id])
        if(member_of_repo[0][0] == 0)
          db.execute("DELETE FROM repository_to_member WHERE org_id=? AND repo_id=? AND member_id=?", [org_id, repo_obj.id, collaborator.id])
          db.execute("INSERT INTO repository_to_member (org_id, repo_id, member_id) VALUES(?, ?, ?)", [org_id, repo_obj.id, collaborator.id])
        end
        db.execute("COMMIT")
      end
    end
  end

end


# [GitHub Client Calls = COUNT(member)]
#   1 call per member to get their data
class SyncMembersMDCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]

    update_member_data(sync_db, context.client)
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

end
