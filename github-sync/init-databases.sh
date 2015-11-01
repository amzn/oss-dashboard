cat db_metadata/db_metadata_schema.sql | sqlite3 $1
cat db_events/db_event_schema.sql | sqlite3 $1
cat db_releases/db_release_schema.sql | sqlite3 $1
cat db_commits/db_commit_schema.sql | sqlite3 $1
cat db_issues/db_issue_schema.sql | sqlite3 $1
cat user_mapping/db_user_schema.sql | sqlite3 $1
