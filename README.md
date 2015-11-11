# Amazon Open Source Program GitHub Dashboard
A dashboard for viewing many GitHub organizations at once. This dashboard is an internal prototype, please try it out, but note it's being published primarily for the purposes of sharing with the TodoGroup. It's hoped that said group will produce a tool that far surpasses this tools limited features. 

Generating the dashboard is intended to occur in three phases.

## Phase 1

Sync data from GitHub. 

Ruby is used to connect to GitHub, pull down the latest data, and update a SQLite Database.

## Phase 2

The latest code is checked out, and review scripts run on the code. Analysis is stored for later use.

## Phase 3

An HTML dashboard is generated from the SQLite Databases and the code analysis.

## Dependencies

The dashboard assumes the following are installed:

 1. SQLite 3.x
 2. SQLite Rubygem - 'sqlite3'
 3. OctoKit Rubygem - 'octokit'
 4. Licensee Rubygem - 'licensee'; though this should go away when the data is provided by OctoKit
 5. XSLT Rubygem - 'xslt'
 6. XML Rubygem - 'xml'

## Setup

* Install the dependencies listed above.
* Create a file (outside of the git clone) to contain your GitHub access token. Set the permissions to 600. 

Example file:

```
 github:
   access_token: 'your github access token'
```

* Create a dashboard configuration file (outside of the git clone).

Example file:

```
  dashboard:
    organizations: ['amzn', 'amznlabs']
    data-directory: /full/path/to/directory/to/store/data
    reports: [ 'DocsReporter', 'LicenseReporter' ]
    db-reports: [ 'UnknownMembersDbReporter', 'No2faDbReporter', 'WikiOnDbReporter', 'EmptyDbReporter' ]
    www-directory: /full/path/to/generate/html/to

    private-access: ['amznlabs']     # Optional
    report-path: ['/full/path/to/directory/of/custom/reports']  # Optional
    db-report-path: ['/full/path/to/directory/of/custom/db-reports']  # Optional
    map-user-script: /full/path/to/script   # Optional
```

### organizations

This lists the organizations that you wish to include in your dashboard. Currently only organization accounts are supported, not user accounts. 

### data-directory

This is where the scripts will store the database and checked out code. 

### reports

Which reports you wish to be executed on the code. Note that LicenseReporter both provides a report and uses the Licensee project to identify the basic top level license file. 

### db-reports

Which reports you wish to be executed on the database. 

### www-directory

Where you want the dashboard output to go.

### Optional: private-access

If your access token is configured so it can see the private side of an organization, adding to this list will enable those features. 

### Optional: report-path

This is a list of paths to look for custom Reporters. 

### Optional: db-report-path

This is a list of paths to look for custom Database Reporters. 

### Optional: map-user-script

Interaction between GitHub's user schema and your own user schema is a common use case for a dashboard. This script is executed to load in your customized data. 

The user schema contains an email address field, to represent your internal login, and an is_employee field, to represent whether they are currently employed. Executing this script is the responsibility of the github-sync/user-mapping subphase. 

## Running

With the configuration file created, you should execute the following:

```
  ruby refresh-dashboard.rb {path to config-dashboard.yml} {path to config-github.yml}
```

To run only part of the system, you can add an additional argument for the phase desired. Available phases are:

```
  init-database
  github-sync
  github-sync/metadata
  github-sync/commits
  github-sync/events
  github-sync/issues
  github-sync/releases
  github-sync/user-mapping
  github-sync/reporting
  pull-source
  review-source
  generate-dashboard
  generate-dashboard/xml
  generate-dashboard/merge
  generate-dashboard/teams-xml
  generate-dashboard/xslt
```

## Helper Tools

You only get 5000 requests an hour to GitHub, so keeping an eye on your current request count can be important. 

```
  ruby github-sync/util/get_rate_limit.rb {path to config-github.yml}
```

The following query shows you the size of each of your tables. It needs porting to Ruby so it can take advantage of the config.

```
  sh github-sync/queries/db-summary.sh {path to database file}
```

## Large Organizations

Because of that 5000 request limit, loading the data for large organizations can be difficult. While in principle you should be able to repeat run the dashboard until your database is full (at least until you hit a repository that would take greater than 5000 requests), this hasn't been tested and the dashboard does not yet fail gracefully. 

Running each phase at a time is advised; chances are you will need to run github-sync/issues repeatedly until full. You can edit the configuration so it only runs on the org you are adding during that manual import, then put the full list back again. 
