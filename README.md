# osa-gitdash
A dashboard for viewing many Git organizations at once.

Generating the dashboard is intended to occurr in three phases.

## Phase 1

Sync data from GitHub. 

Ruby is used to connect to GitHub, pull down the latest data, and update a set of SQLite Databases.

## Phase 2

The latest code is checked out, and review scripts run on the code. Analysis is stored for later use.

## Phase 3

An HTML dashboard is generated from the SQLite Databases and the code analysis.

## Dependencies

The dashboard assumes the following are installed:

 1. SQLite 3.x
 2. SQLite Rubygem - 'sqlite3'
