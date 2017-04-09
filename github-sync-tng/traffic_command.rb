# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
require_relative '../db/lib/trafficStoreLibrary.rb'

require_relative 'base_command'

class SyncTrafficCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_traffic(queue, params[0], params[1])
  end

  def sync_traffic(queue, context, sync_db)

    owners = context.dashboard_config['organizations+logins']

    owners.each do |org|

      unless(context.private_access?(org))
        next
      end

      if(context.login?(org))
        repos=context.client.repositories(org)
      else
        repos=context.client.organization_repositories(org)
      end

      repos.each do |repo_obj|
        queue.push(SyncTrafficForRepoCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
      end

    end

  end

end

class SyncTrafficForRepoCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]

    org=@args['org']
    repo_name=@args['repo']
    repo_full_name="#{org}/#{repo_name}"

    referrers=context.client.top_referrers(repo_full_name, {:accept => 'application/vnd.github.spiderman-preview'})
    db_insert_traffic_referrers(sync_db, referrers, org, repo_name)

    paths=context.client.top_paths(repo_full_name, {:accept => 'application/vnd.github.spiderman-preview'})
    db_insert_traffic_paths(sync_db, paths, org, repo_name)

    views=context.client.views(repo_full_name, {:accept => 'application/vnd.github.spiderman-preview'})
    db_insert_traffic_views(sync_db, views, org, repo_name)

    clones=context.client.clones(repo_full_name, {:accept => 'application/vnd.github.spiderman-preview'})
    db_insert_traffic_clones(sync_db, clones, org, repo_name)

  end

end
