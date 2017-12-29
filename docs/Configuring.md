# Configuring the oss-dashboard

## Configuring the GitHub connection

You will need a GitHub personal access token so that the oss-dashboard can pull the data from GitHub. You can create one on your [settings page](https://github.com/settings/tokens). 

For general use, no specific scopes are required. If you wish to see private organization data (such as Teams, all Members and private Repositories), you will need to enable the 'repo' scope when creating your personal access token.

To confirm your token works, you can access the following and check the response:
https://api.github.com/user?access_token=YOUR_TOKEN_GOES_HERE 

If you see the following, then something went wrong:

```
{
  "message": "Bad credentials",
  "documentation_url": "https://developer.github.com/v3"
}
```

Once you have your token, you will need to decide how to make it available to the oss-dashboard. You can:

1. Store it in an environment variable named GH_ACCESS_TOKEN; this has the advantage of being harder to accidentally commit but is less secure on the environment. 
2. (Recommended) Create a file (outside of the git clone) to contain your GitHub access token. You should set the permissions to 600 so only the logged in user can read the file.

Example file:

```
 github:
   access_token: 'your github personal access token'
   ssl_verify: false    # Optional - for use with GitHub Enterprise deployments with self-signed certificates
```

## Configuring the Dashboard

* Create a dashboard configuration file (outside of the git clone).

For an example file, see 

```
  dashboard:
    organizations: ['amzn', 'amznlabs']       # One, or more,
    logins: ['hyandell']                      #   of these 
    repositories: ['amzn/oss-dashboard']      # are required

    data-directory: /full/path/to/directory/to/store/data
    reports: [ 'DocsReporter', 'LicenseReporter', 'BinaryReporter' ]
    db-reports: [ 'UnknownCollaboratorsDbReporter', 'LeftEmploymentDbReporter', 'UnknownMembersDbReporter', 'WikiOnDbReporter', 'EmptyDbReporter', 'UnchangedDbReporter', 'NoIssueCommentsDbReporter', 'NoPrCommentsDbReporter', 'RepoUnownedDbReporter', 'LabelDbReporter', 'AverageIssueCloseDbReporter', 'AveragePrCloseDbReporter' ]
    www-directory: /full/path/to/generate/html/to

    private-access: ['amznlabs']     # Optional
    report-path: ['/full/path/to/directory/of/custom/reports']  # Optional
    db-report-path: ['/full/path/to/directory/of/custom/db-reports']  # Optional
    map-user-script: /full/path/to/script   # Optional

  database:
    engine: 'postgres'
    username: 'USERNAME'
    password: 'PASSWORD'
    server: 'localhost'
    port: 5432
    database: 'DATABASENAME'

```

### database configuration

Configure the database section above by setting the username, password, server, port and database settings. You can manually setup the table, or if it's not setup oss-dashboard will attempt to set it up for you.

### organizations

This lists the organizations that you wish to include in your dashboard. 

### logins

This lists the user logins that you wish to include in your dashboard. Under the hood the dashboard treats these largely the same, storing the data in the same location.

### repositories

This lists any repositories you wish to include in your dashboard (i.e. pull in a repository rather than every repository in the organization). It currently only supports repositories in organizations.

### data-directory

This is where the scripts will store the database and checked out code. 

### reports

Which reports you wish to be executed on the source code. Note that LicenseReporter both provides a report and uses the Licensee project to identify the basic top level license file. See the Reports documentation to choose which source reports you wish to run. 

### db-reports

Which reports you wish to be executed on the database. See the Reports documentation to choose which db reports you wish to run. 

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

### Optional: Hiding private repositories

If you don't want to download private repositories, you can add that as a configuration option:

```
    hide-private-repositories: true
```
