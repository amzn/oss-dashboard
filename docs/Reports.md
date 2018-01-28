# Reports

There are currently two types of reports available, though the plan is to merge them into the same type.

## DB Reports

These are reports that run against the database. See [Customising](Customising.md) for instructions on how to implement a custom DB Report.

### UnknownCollaboratorsDbReporter

This report shows which of the outside collaborators are not in your user_mapping of GitHub login to Internal Employee login. Maintaining that user mapping is a custom task left to th user.

### LeftEmploymentDbReporter

This report shows which of the organization members/collaborators are flagging as having left the company.

It requires you to perform a custom task and update the users.is_employee column to indicate if people are employees. The idea is that you integrate it into your account removal processes, or you have a nightly LDAP check.

### UnknownMembersDbReporter

This report shows which of the organization members are not in your user_mapping of GitHub login to Internal Employee login. Maintaining that user mapping is a custom task left to th user.

### WikiOnDbReporter

This report shows repositories that have their wikis turned on.

### EmptyDbReporter

This report shows repositories that GitHub is reporting as zero-sized.

### UnchangedDbReporter

This report shows repositories that have not had any changes since the day they were created.

### NoIssueCommentsDbReporter

This report shows open issues from the community with no comments.

### NoPrCommentsDbReporter

This report shows open pull requests from the community with no comments.

### RepoUnownedDbReporter

This report shows repositories that have no team committers.

They may have collaborators, or oss-dashboard may not have had the permissions to see team data.

### LabelDbReporter

This report shows the labels in use, and how many issues + prs, open or closed, are in each.

### LabelCountDbReporter

This report shows the number of open issues and pull requests for a configured list of standard labels. It defaults to the standard list of GitHub labels.

Configuration:

    labels: ['array', 'of', 'labels', 'to', 'include']     ::   Default=['bug', 'duplicate', 'enhancement', 'help wanted', 'invalid', 'question', 'wontfix']

### AverageIssueCloseDbReporter

This report shows the average time each repo takes to close issues.

### AveragePrCloseDbReporter

This report shows the average time each repo takes to close pull requests.

### AverageCloseThisYearDbReporter

This report shows the average time each repo takes to close issues and PRs in the current calendar year. You can filter out specific labels. By default it filters out enhancements.

Configuration:

  labels: ['array', 'of', 'labels', 'to', 'exclude']     ::   Default=['enhancement']

### PublishDbReporter

This report shows recent publish events, and the traffic data surrounding the launch.

## Source Reports

These are reports which are executed on the source code. See [Customising](Customising.md) for instructions on how to implement a custom Source Report.

### DocsReporter

This report shows you *.txt and *.md files in your repositories. Useful for reviews by documentation writers.

### LicenseReporter

This report shows you the repositories that the [licensee](https://github.com/benbalter/licensee) project is unable to either find or identify.

### BinaryReporter

Uses the Linux file command to identify if a file is binary. Empty files and images are filtered out of the list.

