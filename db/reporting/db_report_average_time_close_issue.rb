
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
    issue_query="SELECT repo, COUNT(id), AVG(closed_at::date - created_at::date)::numeric as mttr FROM issues WHERE state='closed' AND org=? GROUP BY org, repo ORDER BY mttr"

    issue_data=sync_db[issue_query, org]
    issue_data.each do |row|
      text << "  <reporting class='issue-report' repo='#{org}/#{row[:repo]}' type='AverageIssueCloseDbReporter'><field>#{org}/#{row[:repo]}</field><field>#{row[:count]}</field><field>#{row[:mttr].to_s('f')}</field></reporting>\n"
    end

    return text
  end

end
