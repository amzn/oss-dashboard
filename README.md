# Amazon Open Source Program GitHub Dashboard (osa-gitdash)
A dashboard for viewing many Git organizations at once.

Generating the dashboard is intended to occur in three phases.

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
 3. OctoKit Rubygem - 'octokit'

## Setup/Running

* Install the dependencies listed above.
* Create a file in the root named config-github.yml containing your GitHub access token. Set the permissions to 600. 

Example file:

```
 github:
   access_token: 'your github access token'
```

* Create a file in the root of the directory named config-dashboard.yml containing the configuration for the dashboard.

Example file:

```
  dashboard:
    organizations: ['amzn', 'aws']
    private-access: ['amzn']
    data-directory: /full/path/to/directory/to/store/data
    report-path: ['/full/path/to/directory/of/custom/reports']  # Optional
    reports: [ 'DocsReporter', 'CustomReporter' ]
    www-directory: /full/path/to/generate/html/to
```
