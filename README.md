# Amazon Open Source Program GitHub Dashboard (osa-gitdash)
A dashboard for viewing many GitHub organizations at once.

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
 4. Licensee Rubygem - 'licensee'; though this should go away when the data is provided by OctoKit

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
    private-access: ['amzn']     # Optional
    data-directory: /full/path/to/directory/to/store/data
    report-path: ['/full/path/to/directory/of/custom/reports']  # Optional
    reports: [ 'DocsReporter', 'LicenseReporter' ]
    www-directory: /full/path/to/generate/html/to
```

### organizations

This lists the organizations that you wish to include in your dashboard. Currently only organization accounts are supported, not user accounts. 

### private-access

If your access token is configured so it can see the private side of an organization, adding to this list will enable those features. 

### data-directory

This is where the scripts will store the database and checked out code. 

### report-path

This is a list containing places to look for custom Reporters. 

### reports

Which reports you wish to be executed on the code. Note that LicenseReporter both provides a report and uses the Licensee project to identify the basic top level license file. 

### www-directory

Where you want the dashboard output to go.

## More Setup/Running

With the configuration file created, you should execute the following:

TODO: This needs to be simplified, too many steps. Also need to consider moving 1 and 6 to Ruby.

 1. init-database.sh {path-to-data-directory}/db/gh-sync.db
 2. github-sync/sync.rb
 3. github-pull/pull_source.rb
 4. review-repos/reporter_runner.rb
 5. generate-dashboard/generate-dashboard-xml.rb
 6. xsltproc generate-dashboard/style/dashboardToHtml.xslt {path-to-data-directory}/dash-xml/{org}.xml > html-file.html
