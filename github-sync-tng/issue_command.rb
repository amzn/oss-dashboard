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
require 'date'
require_relative '../db/lib/issueStoreLibrary.rb'

require_relative 'base_command'

# [GitHub Client Calls = COUNT(Repos)]
class SyncIssuesCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_issues(queue, params[0], params[1])
  end

  def sync_issues(queue, context, sync_db)
    owners = context.dashboard_config['organizations+logins']
    context.feedback.puts " issues"

    owners.each do |org|

      if(context.login?(org))
        repos=context.client.repositories(org)
      else
        repos=context.client.organization_repositories(org)
      end
 
      context.feedback.print "  #{org} "
      repos.each do |repo_obj|
        queue.push(SyncMilestonesCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
        queue.push(SyncLabelsCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
        queue.push(SyncItemsCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
        queue.push(SyncItemCommentsCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
      end
      context.feedback.print "\n"
    end
  
  end

end

# [GitHub Client Calls = COUNT(Repos)]
class SyncMilestonesCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    get_milestones(params[0].client, params[1], "#{@args['org']}/#{@args['repo']}")
  end

  def get_milestones(client, db, orgrepo)
    milestones=client.milestones(orgrepo)
    if(milestones.empty?)
      return
    end
    db.execute("BEGIN TRANSACTION")
    # Wipe Milestones
    db.execute("DELETE FROM milestones WHERE orgrepo=?", [orgrepo])
    # Fill Milestones again
    milestones.each do |milestone|
      db.execute(
        "INSERT INTO milestones " + 
        "(orgrepo, id, html_url, title, state, number, description, creator, open_issues, closed_issues, created_at, updated_at, closed_at, due_on) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [orgrepo, milestone.id, milestone.html_url, milestone.title, milestone.state, milestone.number, milestone.description, milestone.creator.login, milestone.open_issues, milestone.closed_issues, gh_to_db_timestamp(milestone.created_at), gh_to_db_timestamp(milestone.updated_at), gh_to_db_timestamp(milestone.closed_at), gh_to_db_timestamp(milestone.due_on)])
    end
    db.execute("COMMIT")
  end

end

##### Every repo has default labels, so this leads to a lot of repeated replacements #####
# [GitHub Client Calls = COUNT(Repos)]
class SyncLabelsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    get_labels(params[0].client, params[1], "#{@args['org']}/#{@args['repo']}")
  end

  def get_labels(client, db, orgrepo)
    labels=client.labels(orgrepo)
    if(labels.empty?)
      return
    end
    db.execute("BEGIN TRANSACTION")
    # Wipe Labels
    db.execute("DELETE FROM labels WHERE orgrepo=?", [orgrepo])
    # Fill Labels again
    labels.each do |label|
      db.execute("INSERT INTO labels (orgrepo, url, name, color) VALUES (?, ?, ?, ?)", [orgrepo, label.url, label.name, label.color])
    end
    db.execute("COMMIT")
  end

end

# [GitHub Client Calls = Complex]
class SyncItemsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_items(queue, params[0], params[1], @args['org'], @args['repo'])
  end

# TODO: Move this to the engine?
##     begin # Repository access blocked (Octokit::ClientError)
##     rescue Octokit::ClientError
##        issue_db.rollback
##        context.feedback.print '!'
##     end

  def sync_items(queue, context, issue_db, org, repo)
    orgrepo="#{org}/#{repo}"

    issue_db.execute("BEGIN TRANSACTION");
    maxTimestamp=db_getMaxTimestampForRepo(issue_db, orgrepo)               # Get the current max timestamp in the db
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
      issues=context.client.list_issues(orgrepo, { 'state' => 'all', 'since' => ts } )
    else
      issues=context.client.list_issues(orgrepo, { 'state' => 'all' } )
    end
    db_insert_issues(issue_db, issues, org, repo)                           # Insert any new items
    db_link_issues(issue_db, issues, org, repo)
    db_fix_merged_at(issue_db, context.client, issues, org, repo)           # Put in PR specific data - namely merged_at
    db_add_pull_request_files(issue_db, context.client, issues, org, repo)  # Put in PR specific data - namely the files + their metrics
    issue_db.execute("END TRANSACTION");
    context.feedback.print '.'
  end

end
  
  # This should speed things up
  # TODO: Needs to a) do all the db things that are done below in addition to plain inserting
  #       and b) to figure out the repo from each issue returned. Frustratingly it's not in the API of an issue, 
  #       so it seems that one must parse the issue url.
  #def getLatestForOrg(client, issue_db, org)
  #  maxTimestamp=db_getMaxTimestampForOrg(issue_db, org)               # Get the current max timestamp in the db
  #  if(maxTimestamp)
  #    issues=client.org_issues(org, { 'state' => 'all', 'since' => maxTimestamp, 'filter' => 'all' } )
  #  else
  #    issues=client.org_issues(org, { 'state' => 'all', 'filter' => 'all' } )
  #  end
  #  db_insert_issues(issue_db, issues, org, repo)                   # Insert any new items
  #end
  
  
# [GitHub Client Calls = 1]
class SyncItemCommentsCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_item_comments(params[0], params[1], @args['org'], @args['repo'])
  end

  def sync_item_comments(context, issue_db, org, repo)
    orgrepo="#{org}/#{repo}"

    issue_db.execute("BEGIN TRANSACTION");
    # Get the current max timestamp in the db
    maxTimestamp=db_getMaxCommentTimestampForRepo(issue_db, repo)
    if(maxTimestamp)
      # Increment the timestamp by a second to avoid getting repeats
      ts=DateTime.iso8601(maxTimestamp) + Rational(1, 60 * 60 * 24)
      comments=context.client.issues_comments(orgrepo, { 'since' => ts } )
    else
      comments=context.client.issues_comments(orgrepo)
    end
    db_insert_comments(issue_db, comments, org, repo)
    issue_db.execute("COMMIT");
    context.feedback.print '.'
  end

end

