# Amazon Open Source Program GitHub Dashboard
A dashboard for viewing many GitHub organizations, and/or users, at once. 

!!!oss-dashboard now requires PostgreSQL - README needs updating. For the sqlite version, see the 0.2 release!!!

Changes to make:

1) Postgres now needed.
2) Describe how to configure postgres.
3) Drop the SQLite requirement.
4) Gemfile means you can now bundle install the rubygem files.
5) Need to fix the hardcoding of filenames/database name in the util.rb file.
6) Document --xsync, though note that the metadata syncing specifically shouldn't be trusted yet.

---

![Screenshot](screenshots/BasicDashboardExample.png?raw=true)

There are three phases to generating the dashboard.

## Phase 1

Sync data from GitHub. 

Ruby is used to connect to GitHub, pull down the latest data, and update a SQLite Database.

## Phase 2

The latest code is checked out, and review scripts run on the code. Analysis is stored for later use.

## Phase 3

An HTML dashboard is generated from the SQLite Databases (phase 1) and the analysis of the code (phase 2). 

## Dependencies

The dashboard assumes the following are installed:

| Dependency | Use |
| ----- | -------- |
|  SQLite 3.x | Database for local copy of GitHub data |
|  git  | Pulls source from GitHub |
|  Ruby | Executes scripts (tested on version 2.0.0 and 2.2.1) |
|  SQLite Rubygem - 'sqlite3' | Access the database |
|  OctoKit Rubygem - 'octokit' | Access GitHub API |
|  Licensee Rubygem - 'licensee' | Identify licensing, though this should go away when the data is provided by OctoKit |
|  XML Rubygem - 'libxml-ruby' | Parse XML files |
|  XSLT Rubygem - 'libxslt-ruby' | Process XSLT files |

## Setup

* Install the dependencies listed above.
* Decide how to manage your GitHub personal access token.
  * You can store it in an environment variable named GH_ACCESS_TOKEN; this has the advantage of being harder to accidentally commit.
  * Or you can create a file (outside of the git clone) to contain your GitHub access token. Set the permissions to 600. 

Example file:

```
 github:
   access_token: 'your github personal access token'
```

For general use, no specific scopes are required. If you wish to see private organization data (such as Teams, all Members and private Repositories), you will need to enable the 'repo' scope.

* Create a dashboard configuration file (outside of the git clone).

Example file:

```
  dashboard:
    organizations: ['amzn', 'amznlabs']
    logins: ['hyandell']
    data-directory: /full/path/to/directory/to/store/data
    reports: [ 'DocsReporter', 'LicenseReporter', 'BinaryReporter' ]
    db-reports: [ 'UnknownCollaboratorsDbReporter', 'LeftEmploymentDbReporter', 'UnknownMembersDbReporter', 'No2faDbReporter', 'WikiOnDbReporter', 'EmptyDbReporter', 'UnchangedDbReporter', 'NoIssueCommentsDbReporter', 'NoPrCommentsDbReporter', 'RepoUnownedDbReporter', 'LabelDbReporter', 'AverageIssueCloseDbReporter', 'AveragePrCloseDbReporter', 'AverageIssueOpenedDbReporter', 'AveragePrOpenedDbReporter' ]
    www-directory: /full/path/to/generate/html/to

    private-access: ['amznlabs']     # Optional
    report-path: ['/full/path/to/directory/of/custom/reports']  # Optional
    db-report-path: ['/full/path/to/directory/of/custom/db-reports']  # Optional
    map-user-script: /full/path/to/script   # Optional
```

### organizations

This lists the organizations that you wish to include in your dashboard. 

### logins

This lists the user logins that you wish to include in your dashboard. Under the hood the dashboard treats these largely the same, storing the data in the same location.

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

The user db schema contains an email address field, to represent your internal login, and an is_employee field (0=not employed), to represent whether they are currently employed. Executing this script is the responsibility of the github-sync/user-mapping subphase. 

(Warning - clunky system)
The script provides a USER_EMAILS hash of GitHub login to internal email address. It can also provide an updateUserData function to, for example, update the is_employee column. 

For example:

```
  USER_EMAIL = {
    "github-login" => "internal-email-address"
  }

  def updateUserData(feedback, dashboard_config, client, sync_db)
    # code to talk to internal employment database and update the users.is_employee field to 0 if someone has left
  end
```

### Optional: license-hashes

The license report both identifies licenses for the Repository Metrics section, and provides information on why it could not find the license in its report output. When a license file is available and can't be recognized, it includes the Licensee project's hash. One can provide a separate YAML file to identify licenses that the Licensee project is unable to identify.

This is configured in two steps. Firstly, add a line to your dashboard config pointing to your license-hashes.yml file:

```
    license-hashes: '/full/path/to/license-hashes.yml'
```

Then creates that license-hashes.yml file with content similar to:

```
   - name: 'Custom License A'
     hash: 'c189e0a7f6a535af91b0d3e1b1a3de1ea4443d69'
   - name: 'Custom License B'
     hash: '84b3be39b2d06ca7b5afe43b461544f7dd7c2f1a'
```

These hashes are found on the Repository -> Reports -> License Report, which saves you having to write code against Licensee to identify the hash. 

## Running

With the configuration file created, you should execute the following:

```
  # Instead of providing the --ghconfig file, you can set the 
  # GH_ACCESS_TOKEN environment variable with your access token.
  ruby refresh-dashboard.rb --ghconfig {path to config-github.yml} {path to config-dashboard.yml} 
```

For large repositories, or for a quick review, you can use the --light flag. This creates a database of only the metadata and generates a dashboard. 

```
  # Instead of providing the --ghconfig file, you can set the 
  # GH_ACCESS_TOKEN environment variable with your access token.
  ruby refresh-dashboard.rb --light --ghconfig {path to config-github.yml} {path to config-dashboard.yml} 
```

To run only part of the system, you can add an additional argument for the phase desired. This can be useful to fill in data after running the light flag.

```
  # Instead of providing the --ghconfig file, you can set the 
  # GH_ACCESS_TOKEN environment variable with your access token.
  ruby refresh-dashboard.rb --ghconfig {path to config-github.yml} {path to config-dashboard.yml} {phase}
```

Available phases are:

| Phase | Description |
| ----- | -------- |
|  init-database | Initializes the database file |
|  github-sync | Syncs all the data down from GitHub (runs all of the github-sync/ phases below) |
|  github-sync/metadata | Syncs only the metadata (org, repo, teams, org-members etc) |
|  github-sync/commits | Syncs only the commit data |
|  github-sync/events | Syncs only the event stream |
|  github-sync/issues | Syncs the issue data - note that this is typically the heaviest initial load |
|  github-sync/issue-comments | Syncs the issue comments |
|  github-sync/releases | Syncs the release data |
|  github-sync/user-mapping | Loads your user-mapping file into the database |
|  github-sync/reporting | Runs the configured DB Reports |
|  pull-source | Pulls down the source code from GitHub |
|  review-source | Runs your source Reports on the pulled source code |
|  generate-dashboard | Generates a dashboard (runs all of the generate-edashboard/ phases below)|
|  generate-dashboard/xml | Outputs the XML for organizations |
|  generate-dashboard/merge | Merges the organization XML into a single XML file |
|  generate-dashboard/teams-xml | Splits the organizations up into separate Team XML files |
|  generate-dashboard/xslt | Turns the XML files into HTML |

## Helper Tools

You only get 5000 requests an hour to GitHub, so keeping an eye on your current request count can be important. 

```
  # Instead of providing the file, you can set the 
  # GH_ACCESS_TOKEN environment variable with your access token.
  ruby github-sync/util/get_rate_limit.rb --ghconfig {path to config-github.yml}
```

The following query shows you the size of each of your tables. It needs porting to Ruby so it can take advantage of the config.

```
  ruby github-sync/queries/db-summary.rb {path to database file}
```

## Large Organizations

Because of that 5000 request limit, loading the data for large organizations can be difficult. While in principle you should be able to repeat run the dashboard until your database is full (at least until you hit a repository that would take greater than 5000 requests), this hasn't been tested and the dashboard does not yet fail gracefully. 

Running each phase at a time is advised; chances are you will need to run github-sync/issues repeatedly until full. You can edit the configuration so it only runs on the org you are adding during that manual import, then put the full list back again. 

## Notes on Output Warnings

By default the refresh_dashboard.rb script outputs '.' characters to show it's taken care of a repository (or whatever the 'atom' being operated on is in that phase). Sometimes it outputs a '!'. Here's why:

* github-sync/commits - An '!' here means it skipped an empty repository to avoid an Octokit error. 

## Bootstrap Themes

The HTML generated relies, amongst other libraries, on Bootstrap. The HTML files look for a file named bootstrap-theme.css in the same directory, allowing you to customize the look and feel of the dashboard (typically by finding a theme you like and using that). 

