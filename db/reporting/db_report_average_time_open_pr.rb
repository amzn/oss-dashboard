
class AveragePrOpenedDbReporter < DbReporter

  def name()
    return "Average Pull Request Time Opened"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the average time each repo's open pull requests have been opened"
  end

  def db_columns()
    return [ ['Repo', 'org/repo'], "Count of open pull requests", "Average age of open pull requests" ]
  end

  def db_report(context, org, sync_db)

    text = ""
    issue_query="SELECT repo, COUNT(id), ROUND(AVG(to_char(now()::date, 'J')::integer - to_char(created_at::date,'J')::integer), 1) as age FROM pull_requests WHERE state='open' AND org=? GROUP BY org, repo ORDER BY age"

    issue_data=sync_db[issue_query, org]
    issue_data.each() do |row|
        text << "  <reporting class='issue-report' repo='#{org}/#{row[:repo]}' type='AveragePrOpenedDbReporter'><field>#{org}/#{row[:repo]}</field><field>#{row[:count]}</field><field>#{row[:age]}</field></reporting>\n"
    end

    return text
  end

end
