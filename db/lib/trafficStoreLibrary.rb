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

require "yaml"
require "date"

  def gh_to_db_timestamp(timestamp)
    # Convert format '2014-10-31 23:21:44 UTC' to '2006-03-10T23:33:03+00:00'
    if(timestamp)
      return timestamp.to_s.sub(/ /,'T').sub(/ UTC/, '+00:00')
    else
      return timestamp
    end
  end

  def db_insert_traffic_referrers(db, referrers, org, repo)
    begin
      db.transaction do
        referrers.each do |referrer|
            db[
             "INSERT INTO traffic_referrers (
                org, repo, referrer, count, uniques, recorded_at
              )
              VALUES ( ?, ?, ?, ?, ?, CURRENT_TIMESTAMP )",
              org,
              repo,
              referrer['referrer'],
              referrer['count'],
              referrer['uniques']
              ].insert
        end
      end
    rescue => e
      puts "Error during processing: #{$!}"
    end
  end

  def db_insert_traffic_paths(db, paths, org, repo)
    begin
      db.transaction do
        paths.each do |path|
            db[
             "INSERT INTO traffic_popular_paths (
                org, repo, path, count, uniques, recorded_at
              )
              VALUES ( ?, ?, ?, ?, ?, CURRENT_TIMESTAMP )",
              org,
              repo,
              path['path'],
              path['count'],
              path['uniques']
              ].insert
        end
      end
    rescue => e
      puts "Error during processing: #{$!}"
    end
  end

  def db_insert_traffic_views(db, views, org, repo)
    begin
      db.transaction do
        db[
         "INSERT INTO traffic_views_total (
            org, repo, count, uniques, recorded_at
          )
          VALUES ( ?, ?, ?, ?, CURRENT_TIMESTAMP )",
          org,
          repo,
          views['count'],
          views['uniques']
          ].insert
        views['views'].each do |view|
            db[
              "DELETE FROM traffic_views_daily WHERE org=? AND repo=? AND timestamp=?",
              org, repo, gh_to_db_timestamp(view['timestamp'])
              ].delete
            db[
             "INSERT INTO traffic_views_daily (
                org, repo, count, uniques, timestamp
              )
              VALUES ( ?, ?, ?, ?, ? )",
              org,
              repo,
              view['count'],
              view['uniques'],
              gh_to_db_timestamp(view['timestamp'])
              ].insert
        end
      end
    rescue => e
      puts "Error during processing: #{$!}"
    end
  end
  def db_insert_traffic_clones(db, clones, org, repo)
    begin
      db.transaction do
        db[
         "INSERT INTO traffic_clones_total (
            org, repo, count, uniques, recorded_at
          )
          VALUES ( ?, ?, ?, ?, CURRENT_TIMESTAMP )",
          org,
          repo,
          clones['count'],
          clones['uniques']
          ].insert
        clones['clones'].each do |clone|
          db[
            "DELETE FROM traffic_clones_daily WHERE org=? AND repo=? AND timestamp=?",
            org, repo, gh_to_db_timestamp(clone['timestamp'])
            ].delete
          db[
           "INSERT INTO traffic_clones_daily (
              org, repo, count, uniques, timestamp
            )
            VALUES ( ?, ?, ?, ?, ? )",
            org,
            repo,
            clone['count'],
            clone['uniques'],
            gh_to_db_timestamp(clone['timestamp'])
            ].insert
        end
      end
    rescue => e
      puts "Error during processing: #{$!}"
    end
  end
