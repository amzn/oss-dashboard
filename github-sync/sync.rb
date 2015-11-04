#!/usr/bin/env ruby

require 'rubygems'
require 'octokit'
require 'date'
require 'yaml'

require_relative 'db_metadata/sync-metadata.rb'
require_relative 'db_commits/sync-commits.rb'
require_relative 'db_events/sync-events.rb'
require_relative 'db_issues/sync-issues.rb'
require_relative 'db_releases/sync-releases.rb'
require_relative 'user_mapping/sync-users.rb'

def github_sync(dashboard_config, client, run_one)

  db_filename=File.join(dashboard_config['data-directory'], 'db', 'gh-sync.db');

  sync_db=db_open(db_filename)

  if(not(run_one) or run_one=='github-sync/metadata')
    sync_metadata(dashboard_config, client, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/commits')
    sync_commits(dashboard_config, client, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/events')
    sync_events(dashboard_config, client, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/issues')
    sync_issues(dashboard_config, client, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/releases')
    sync_releases(dashboard_config, client, sync_db)
  end
  if(not(run_one) or run_one=='github-sync/user-mapping')
    sync_user_mapping(dashboard_config, client, sync_db)
  end

  sync_db.close

end

