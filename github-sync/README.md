# GitHub Sync

Each of the db_ subdirectories syncs a set of data from GitHub.

The top level contains:

* A script to initialize the databases.

The subdirectories contain:

* A schema file
* A library for interacting with the database.
* A ruby script to sync from GitHub.

The queries/ folder contains some example queries to review the data.

Via the user_mapping/ folder, a github-login=>private-email mapping is maintained and loaded into each database.
