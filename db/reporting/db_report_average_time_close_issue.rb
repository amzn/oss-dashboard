
class AverageIssueCloseDbReporter < DbReporter

  def get_table_name()
    return 'issues'
  end

  def name()
    return "Average Issue Close Time"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the average time each repo takes to close #{get_table_name()}"
  end

  def db_columns()
    return [ ['Repo', 'org/repo'], 
             "<1 month: Closed", "<1 month: MTTR", "<1 month: Still Open",
             "<1 quarter: Closed", "<1 quarter: MTTR", "<1 quarter: Still Open",
             "<1 year: Closed", "<1 year: MTTR","<1 year: Still Open",
             "All time: Closed", "All time: MTTR", "All time: Still Open",
           ]
  end

  def db_report(context, repo, sync_db)

    text = ''

    queries = { 
                '1_month' => "AND created_at > now() - interval '1 month'",
                '1_quarter' => "AND created_at > now() - interval '3 months'",
                '1_year' => "AND created_at > now() - interval '1 year'",
                'all_time' => '',
              }

    issue_data=Array.new
    queries.each do |name, dateQuery|
      issue_query="SELECT COUNT(id) AS count, ROUND(AVG(closed_at::date - created_at::date)::numeric, 2) as mttr FROM #{get_table_name()} WHERE state='closed' #{dateQuery} AND org=? AND repo=? GROUP BY org, repo"
      result=sync_db[issue_query, repo.owner.login, repo.name].first
      if(result)
        issue_data << result[:count] << result[:mttr].to_s('f')
      else
        issue_data << 0 << 0
      end

      still_open_query="SELECT COUNT(id) AS count FROM #{get_table_name()} WHERE state='open' #{dateQuery} AND org=? AND repo=? GROUP BY org, repo"
      result=sync_db[still_open_query, repo.owner.login, repo.name].first
      if(result)
        issue_data << result[:count]
      else
        issue_data << 0
      end
    end

    text << "  <reporting class='issue-report' repo='#{repo.full_name}' type='#{self.class.name}'><field>#{repo.full_name}</field>"
    issue_data.each do |field|
      text << "<field>#{field}</field>"
    end

    text << "</reporting>\n"

    return text
  end

end
