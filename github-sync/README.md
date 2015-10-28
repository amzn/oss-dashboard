# GitHub Sync

Each of the db_ subdirectories syncs a set of data from GitHub.

The subdirectories contain:

* A schema file
* A script to initialize the database.
* A ruby script to sync from GitHub.

The queries/ folder contains some example queries to review the data.

Via the user_mapping/ folder, a github-login=>private-email mapping is maintained and loaded into each database.

The code relies on two configuration files in the parent directory:

* ../github-config.yaml
* ../dashboard-config.yaml

## TODO

The intent is to merge these into a single database file; and to move from SQLite to PostgreSQL.
