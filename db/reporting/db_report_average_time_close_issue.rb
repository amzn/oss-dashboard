
class AverageIssueCloseDbReporter < DbReporter

  def name()
    return "Average Issue Close Time"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the average time each repo takes to close issues"
  end

  def db_columns()
    return [ ['Repo', 'org/repo'], "Count of closed issues", "Average time to close issues" ]
  end

  def db_report(context, org, sync_db)

    text = ""
    issue_query="SELECT repo, COUNT(id), ROUND(AVG( julianday(closed_at) - julianday(created_at) ), 1) as mttr FROM issues WHERE state='closed' AND org=? GROUP BY org, repo ORDER BY mttr"

    issue_data=sync_db[issue_query, [org]]
    issue_data.each() do |row|
        text << "  <reporting class='issue-report' repo='#{org}/#{row[0]}' type='AverageIssueCloseDbReporter'><field>#{org}/#{row[0]}</field><field>#{row[1]}</field><field>#{row[2]}</field></reporting>\n"
    end

    return text
  end

end
