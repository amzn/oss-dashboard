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

require "yaml"
require "sqlite3"
require "date"

  # Need to double-check that the hash YAML is simple enough to also be legal JSON. 
  def flatten_event_payload(event)
    case event.type
    when 'CreateEvent'
      return YAML::dump({ 'ref_type' => event.payload.ref_type, 'description' => event.payload.description })
    when 'DeleteEvent'
      return YAML::dump({ 'ref_type' => event.payload.ref_type })
    when 'DeploymentEvent'
      return YAML::dump({ 'name' => event.payload.name })
    when 'ForkEvent'
      return YAML::dump({ 'forkee' => event.payload.forkee['full_name'] })
    when 'GollumEvent'
         ## TODO: pages[][page_name]
      return YAML::dump({ 'action' => event.payload.action })
    when 'IssuesEvent'
      return YAML::dump({ 'action' => event.payload.action, 'issue' => event.payload.issue['url'] })
    when 'IssueCommentEvent'
      return YAML::dump({ 'action' => event.payload.action, 'issue' => event.payload.issue['url'] })
    when 'MemberEvent'
      return YAML::dump({ 'action' => event.payload.action, 'member' => event.payload.member['login'] })
    when 'MembershipEvent'
      return YAML::dump({ 'action' => event.payload.action, 'member' => event.payload.member['login'], 'team' => event.payload.team['name'], 'scope' => event.payload.scope })
    when 'PullRequestEvent'
      return YAML::dump({ 'action' => event.payload.action, 'pull_request' => event.payload.pull_request['url'] })
    when 'PullRequestReviewCommentEvent'
      return YAML::dump({ 'action' => event.payload.action, 'pull_request' => event.payload.pull_request['url'] })
    when 'PushEvent'
      return YAML::dump({ 'size' => event.payload.size })
    when 'ReleaseEvent'
      return YAML::dump({ 'action' => event.payload.action, 'release' => event.payload.release['url'] })
    when 'RepositoryEvent'
      return YAML::dump({ 'action' => event.payload.action, 'repository' => event.payload.repository['full_name'] })
    when 'StatusEvent'
      return YAML::dump({ 'state' => event.payload.state, 'sha' => event.payload.sha })
    when 'TeamAddEvent'
      return YAML::dump({ 'team' => event.payload.team['name'], 'repository' => event.payload.repository['full_name'] })
    when 'WatchEvent'
      return YAML::dump({ 'action' => event.payload.action })
    else 
      #  CommitCommentEvent
      #  DeploymentStatusEvent
      #  DownloadEvent - No longer exists
      #  FollowEvent - No longer exists
      #  ForkApplyEvent - No longer exists
      #  GistEvent - No longer exists
      #  PageBuildEvent
      #  PublicEvent
      return ''
    end
  end

  # TODO: Currently the event payload storage is BIG. And a little useless.
  #       I need to take each event type that is known about, and convert the GitHub object into an array of hash.
  #       If not known, it should store the whole object, while wincing. 
  def db_insert_events(db, events)
    db.execute("BEGIN TRANSACTION");
    events.each do |event|
        flatPayload=flatten_event_payload(event)
        db.execute(
         "INSERT INTO events (
            id, type, actor, org, repo, public, created_at, payload
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ?)",
          [event.id, event.type, event.actor.login, event.org.login, event.repo.name, event.public.to_s, event.created_at.to_s, flatPayload] )
#        puts "  Inserted: #{event.id}"
    end
    db.execute("END TRANSACTION");
  end

  def db_getMaxIdForOrg(db, org)
    db.execute( "select max(id) from events where org='#{org}'" ) do |row|
      return row[0]
    end
  end

  def db_getMaxIdForRepo(db, repo)
    db.execute( "select max(id) from events where repo='#{repo}'" ) do |row|
      return row[0]
    end
  end
