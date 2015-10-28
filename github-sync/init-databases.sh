
cat db_events/db_event_schema.sql | sqlite3 db/gh-sync.db
cat db_releases/db_release_schema.sql | sqlite3 db/gh-sync.db
cat db_commits/db_commit_schema.sql | sqlite3 db/gh-sync.db
cat user_mapping/db_user_schema.sql | sqlite3 db/gh-sync.db
