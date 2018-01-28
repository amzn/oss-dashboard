# Customising your OSS Dashboard

There are three areas of customisation possible with oss-dashboard. The first two are plugging in your own reporting, the last is setting a custom theme for the web pages.


## Writing a DB or Source Report

Note that the plan is to merge DB and Source reports into the same API. As the process/API is very similar, we'll cover them both in this section.

### Configurating

Custom DB Reports are configured via the optional report path configurations in the dashboard configuration:

    db-report-path: ['/full/path/to/directory/of/custom/db-reports']
    report-path: ['/full/path/to/directory/of/custom/reports']

Any report dropped into one of the report path directories will become available.

### Implementing

Reports are implemented by extending the relevant Report class. For a DB report it means the following:

```
require_relative 'db_reporter'

class YourNameDbReporter < DbReporter
```

For a Source report it means:

```
require_relative 'reporter'

class BinaryReporter < Reporter
```

In both cases a Report needs to implement the following metadata methods:

```
  def name()
    return "Short Name for Report"
  end

  def describe()
    return "A longer description of the report"
  end

  # A type of the report; can be repo-report, issue-report or user-report.
  # This determines which tab in the dashboard it appears in.
  def report_class()
    return 'repo-report'
  end
```

If you are implementing a DB report, you then implement this method:

```
  def db_report(context, repo, sync_db)
```

If you are implementing a Source report, you then implement this method:

```
  def report(context, repo, repodir)
```

Two simple examples of reports are [Empty DB Report](../db/reporting/db_report_empty.rb) and [Document Source Report](../review-repos/report_docs.rb).


## Setting a Custom Theme

OSS Dashboard relies on Bootstrap, and thus Bootstrap Themes are available. The generated HTML pages include a __bootstrap-theme.css__ file if one is there (if not your browser will quietly give you a warning). Drop this file into your generated web directory and your theme will be applied. See the [Bootstrap Theme page](https://themes.getbootstrap.com/) for more information on finding/implementing themes.
