# Running oss-dashboard

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
|  generate-dashboard | Generates a dashboard (runs all of the generate-dashboard/ phases below)|
|  generate-dashboard/xml | Outputs the XML for organizations |
|  generate-dashboard/merge | Merges the organization XML into a single XML file |
|  generate-dashboard/teams-xml | Splits the organizations up into separate Team XML files |
|  generate-dashboard/xslt | Turns the XML files into HTML |

## Large Organizations

Because of that 5000 request limit, loading the data for large organizations can be difficult. While in principle you should be able to repeat run the dashboard until your database is full (at least until you hit a repository that would take greater than 5000 requests), this hasn't been tested and the dashboard does not yet fail gracefully.

Running each phase at a time is advised; chances are you will need to run github-sync/issues repeatedly until full. You can edit the configuration so it only runs on the org you are adding during that manual import, then put the full list back again.

Another approach is to turn on the --xsync flag for issues/commits/releases/events. This uses a queue to synchronize the data rather than trying to do it all in one go. It's not recommended that you use the --xsync flag for metadata as it doesn't cleanly delete old data that has gone from GitHub.

## Notes on Output Warnings

By default the refresh_dashboard.rb script outputs '.' characters to show it's taken care of a repository (or whatever the 'atom' being operated on is in that phase). Sometimes it outputs a '!'. Here's why:

* github-sync/commits - An '!' here means it skipped an empty repository to avoid an Octokit error.

## Helper Tools

You only get 5000 requests an hour to GitHub, so keeping an eye on your current request count can be important. This script lets you know how many tokens you have left. 

```
  # Instead of providing the file, you can set the
  # GH_ACCESS_TOKEN environment variable with your access token.
  ruby github-sync/util/get_rate_limit.rb --ghconfig {path to config-github.yml}
```

The following query shows you the size of each of your tables. It needs porting to Ruby so it can take advantage of the config. It can be run for everything, or just for a single organization. 

```
  ruby db/queries/db-summary.rb {path to config-dashboard.yml} [optional organization login]
```
