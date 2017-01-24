
class AveragePrCloseDbReporter < DbReporter

  def name()
    return "Average Pull Request Close Time"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the average time each repo takes to close pull requests"
  end

  def db_columns()
    return [ ['Repo', 'org/repo'], "Count of closed pull requests", "Average time to close pull requests" ]
  end

  def db_report(context, org, sync_db)

    text = ""
    pr_query="SELECT repo, COUNT(id), AVG(closed_at::date - created_at::date)::numeric as mttr FROM pull_requests WHERE state='closed' AND org=? GROUP BY org, repo ORDER BY mttr"

    pr_data=sync_db[pr_query, org]
    pr_data.each() do |row|
        text << "  <reporting class='issue-report' repo='#{org}/#{row[:repo]}' type='AveragePrCloseDbReporter'><field>#{org}/#{row[:repo]}</field><field>#{row[:count]}</field><field>#{row[:mttr].to_s('f')}</field></reporting>\n"
    end

    return text
  end

end
