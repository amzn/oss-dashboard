# Amazon Open Source Program GitHub Dashboard

There is a distinct lack of tooling for GitHub admins and Open Source program managers who oversee many GitHub organizations. The oss-dashboard provides a view over many GitHub projects, allowing for custom reporting on the synchronized data.

![Screenshot](docs/screenshots/BasicDashboardExample.png?raw=true)

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

An HTML dashboard is generated from the data and reviews.

## Further Instructions

The following documents provided further information

 * [Installing from source](docs/InstallingFromSource.md)
 * [Installing via Docker](docs/InstallingViaDocker.md)
 * [Configuring](docs/Configuring.md)
 * [Reports](docs/Reports.md)
 * [Running](docs/Running.md)
 * [Customising](docs/Customising.md)

## Project Direction

The high level plan is to work on the following items:

* Custom dashboards. This is mostly implemented and needs the configuration approach implemented.
* Move away from XSLT to ERB (or another Ruby based HTML generator). Reality is that XSLT seems to scare people.
* Move away from a single HTML page to many HTML pages. It was useful to wrap up a report into a single HTML and mail around, but now the lack of deep linking is a pain.
* Add a Repository dashboard. Currently repositories are only viewed in the multiple (ie: each dashboard displays multiple repositories at once). Having a dashboard for each repository will allow for more data.
* Merge the reporting. Currently there are Database and Source code report structures. The plan is to merge them together.
* Run a live demo, possibly using Apache MXNet and its dependencies as the data.
* Consider using GHTorrent as the source of data; though the SQL database is still very attractive and simplifies the reporting step.
* Add more reports!
* Pull the source apart. Currently it's all driven from one high level ruby file. Splitting into independent pieces (syncing, reports, dashboard generation) will allow each section to have more focus.
* Custom charting + custom visualization in general so that a custom-viz plugin can pair with a custom-report plugin, without the engine in the middle having to understand their format.

## Contributing

Contributions are much appreciated, be they bug reports, ideas or patches. See the [Contributing](CONTRIBUTING.md) file for more information.

## Other Projects of Interest

Or rather, some useful lists of Other Projects of Interest:

* https://chaoss.community/
* https://github.com/todogroup/awesome-oss-mgmt
