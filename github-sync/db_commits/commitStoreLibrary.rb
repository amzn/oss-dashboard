#!/usr/bin/ruby

require "yaml"
require "sqlite3"
require "date"

  def db_open(filename)
    db = SQLite3::Database.new filename
    return db
  end

  def db_delete_all(db)
    db.execute("DELETE FROM commits")
  end

  def gh_to_db_timestamp(timestamp)
    # Convert format '2014-10-31 23:21:44 UTC' to '2006-03-10T23:33:03+00:00'
    if(timestamp)
      return timestamp.to_s.sub(/ /,'T').sub(/ UTC/, '+00:00')
    else
      return timestamp
    end
  end

  def db_insert_commits(db, commits, org, repo)
    db.execute("BEGIN TRANSACTION");
    commits.each do |commit|
        db.execute(
         "INSERT INTO commits (
            sha, message, tree, org, repo, author, authored_at, committer, committed_at, comment_count
          )
          VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )",
        [
         commit['sha'],
         commit['commit']['message'],
         commit['commit']['tree']['sha'],
         org,
         repo,
         commit['commit']['author']['name'],
         gh_to_db_timestamp(commit['commit']['author']['date']),
         commit['commit']['committer']['name'],
         gh_to_db_timestamp(commit['commit']['committer']['date']),
         commit['commit']['comment_count'] 
        ] )
#        puts "  Inserted: #{commit.sha}"
    end
    db.execute("END TRANSACTION");
  end

  def gh_to_db_timestamp(timestamp)
    # Convert format '2014-10-31 23:21:44 UTC' to '2006-03-10T23:33:03+00:00'
    if(timestamp)
      return timestamp.to_s.sub(/ /,'T').sub(/ UTC/, '+00:00')
    else
      return timestamp
    end
  end

  def db_getMaxTimestampForRepo(db, org, repo)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(committed_at) from commits where org='#{org}' and repo='#{repo}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end

  def db_getMaxTimestampForOrg(db, org)
    # Normally '2015-04-18 14:17:02 UTC'
    # Need '2015-04-18T14:17:02Z'
    db.execute( "select max(committed_at) from commits where org='#{org}'" ) do |row|
      timestamp=row[0]
      if(timestamp)
          return timestamp.to_s.sub(/ /, 'T').sub(/ /, 'Z')
      else
          return timestamp
      end
    end
  end
