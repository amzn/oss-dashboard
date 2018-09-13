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

require_relative 'base_command'

# DELETE THIS AND FOLD INTO sync???
class SyncReleasesCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    sync_releases(queue, params[0], params[1])
  end

  def sync_releases(queue, context, sync_db)

    owners = context.dashboard_config['organizations+logins']

    # GH COST = owners.length
    owners.each do |org|

      repos=context.repositories(org)

      # There's no @since here, so it's removing current data and replacing with all release info from GitHub
      # Could use this for initial load and use the event data stream for updates
      repos.each do |repo_obj|
        queue.push(SyncReleaseCommand.new( { 'org' => org, 'repo' => repo_obj.name } ) )
      end

    end

  end

end

class SyncReleaseCommand < BaseCommand

  # params=(context, sync_db)
  def run(queue, *params)
    context=params[0]
    sync_db=params[1]

    orgrepo="#{@args['org']}/#{@args['repo']}"
    releases=context.client.releases(orgrepo)
    db_insert_releases(sync_db, @args['org'], @args['repo'], releases)   # Replaces existing with these

  end

  # TODO: Move to a db library
  def db_insert_releases(db, org, repo, releases)
    db.transaction do
      releases.each do |release|
          db[
           "DELETE FROM releases WHERE org=? AND repo=? AND id::int=?", org, repo, release.id].delete

          # Sometimes there is no author. Instead, fill in the data with the first file's uploader
          if(release.author)
              author=release.author.login
          else
              if(release.assets and release.assets[0] and release.assets[0].uploader)
                  author=release.assets[0].uploader.login
  #                puts "Unable to find an author for #{release.html_url}; using uploader: #{author}"
              else
                  author=nil
  #                puts "Unable to find an author or uploader for #{release.html_url}"
              end
          end

	  # only include releases that were published
	  if(release.published_at)
	          db[
        	   "INSERT INTO releases (
	              org, repo, id, html_url, tarball_url, zipball_url, tag_name, name, body, created_at, published_at, author
	            )
	            VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
	            org, repo, release.id, release.html_url, release.tarball_url, release.zipball_url, release.tag_name, release.name, release.body, release.created_at.to_s,
	            release.published_at.to_s, author].insert
	  end
      end
    end
  end

end
