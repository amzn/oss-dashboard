# Amazon Open Source Program GitHub Dashboard

There is a distinct lack of tooling for GitHub admins and Open Source program managers who oversee many GitHub organizations. The oss-dashboard provides a view over many GitHub projects, allowing for custom reporting on the synchronized data. 

![Screenshot](../screenshots/BasicDashboardExample.png?raw=true)

---

## High level description of the architecture

There are three parts to the oss-dashboard. 

### Part 1 - Syncing

1. Ruby is used to connect to GitHub, pull down the latest data, and update a PostgreSQL Database.
2. Git is used to check out the latest version of the source from each GitHub repository.

### Phase 2 - Reviewing

1. Ruby is used to run reports on the database.
2. Ruby is also used to run reports on the checked out source code. 

### Phase 3 - Generate the dashboard

An HTML dashboard is generated from the PostgreSQL Database (phase 1) and the analysis of the data (phase 2). 

## Further Instructions

The following documents provided further information

 * [Installing from source](InstallingFromSource.md)
 * [Installing via Docker](InstallingViaDocker.md)
 * [Configuring](Configuring.md)
 * [Running](Running.md)
 * [Customising](Customising.md)
 * [Contributing](CONTRIBUTING.md)

## Project Direction

## Contributing
	
## Other Projects of Interest
