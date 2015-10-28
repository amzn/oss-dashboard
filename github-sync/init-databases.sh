
cat db_events/db_event_schema.sql | sqlite3 db/gh-sync.db
cat db_releases/db_release_schema.sql | sqlite3 db/gh-sync.db
