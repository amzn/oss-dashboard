require_relative './db_report_average_time_close_issue'

class AveragePrCloseDbReporter < AverageIssueCloseDbReporter

  def get_table_name()
    return 'pull_requests'
  end

  def name()
    return "Average Pull Request Close Time"
  end

  def describe()
    return "This report shows the average time each repo takes to close pull requests"
  end

end
