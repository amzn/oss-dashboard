
class AverageCloseThisYearDbReporter < DbReporter

  LIGHT_CORAL='F08080'
  LIGHT_GREEN='90EE90'

  def name()
    return "Average Issue/PR Close Time This Year"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the average time each repo takes to close issues and PRs in the current calendar year. This report does NOT include enhancements"
  end

  # Cheating and using the labels type to color the field
  def db_columns()
    return [ ['Repo', 'org/repo'], 
             '# Issues Closed', ['Average Issue Close Time', 'labels'],
             '# PRs Closed', ['Average PR Close Time', 'labels'],
           ]
  end

  def db_report(context, repo, sync_db)

    # Arbitrary defaults
    mttr_sla=21
    labels_filter=['enhancement']

    # Let's you customize the defaults
    # TODO: Need to do type checking
    if(context.dashboard_config.has_key?('AverageCloseThisYearDbReporter'))
      if(context.dashboard_config['AverageCloseThisYearDbReporter'].has_key?('labels'))
        labels_filter=context.dashboard_config['AverageCloseThisYearDbReporter']['labels']
      end
      if(context.dashboard_config['AverageCloseThisYearDbReporter'].has_key?('labels'))
        mttr_sla=context.dashboard_config['AverageCloseThisYearDbReporter']['mttr_sla']
      end
    end

    text = ''

    # NOTE: The schema is not well designed for this, so doing the manipulation in Ruby

    # First get the repo's Item IDs with the labels to ignore
    filter_query=<<-SQL
      SELECT item_id as id
        FROM item_to_label i2L, labels L
       WHERE L.url=i2L.url
         AND i2L.url LIKE ?
         AND L.name IN ?
    SQL
    url_param="https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/labels/%"
    filter_ids=sync_db[filter_query, url_param, labels_filter]

    # Create a lookup Set
    filter_id_set=Set.new
    filter_ids.each do |row|
      filter_id_set << row[:id].to_s     # Annoyingly the item table/issue view has id as a string
    end

    # Then get the ID and age of each resolved ticket
    issue_query=<<-SQL
      SELECT I.id as id, I.closed_at::date - I.created_at::date as age
        FROM issues I
        WHERE I.state='closed'
          AND EXTRACT(YEAR FROM I.closed_at) = EXTRACT(YEAR FROM now())
          AND I.org=?
          AND I.repo=?
    SQL
    issue_result=sync_db[issue_query, repo.owner.login, repo.name]


    # Work out the Count and MTTR in Ruby
    issue_count=0
    issue_mttr=0
    if(issue_result)
      issue_combined_age=0
      issue_result.each do |row|
        if(filter_id_set.include?(row[:id]))
          next
        end
        issue_count=issue_count + 1
        issue_combined_age=issue_combined_age + row[:age]
      end
      unless(issue_count==0)
        issue_mttr=issue_combined_age / issue_count
      end
    end

    # Not filtering pull requests, so let the database take care of things
    pr_query="SELECT COUNT(id) AS count, ROUND(AVG(closed_at::date - created_at::date)::numeric, 2) as mttr FROM pull_requests WHERE state='closed' AND EXTRACT(YEAR FROM closed_at) = EXTRACT(YEAR FROM now()) AND org=? AND repo=? GROUP BY org, repo"
    pr_result=sync_db[pr_query, repo.owner.login, repo.name].first

    # Output the data
    text << "  <reporting class='issue-report' repo='#{repo.full_name}' type='#{self.class.name}'><field>#{repo.full_name}</field>"

    color=LIGHT_GREEN
    if(issue_mttr > mttr_sla)
      color=LIGHT_CORAL
    end
    text << "<field>#{issue_count}</field><field><label color='#{color}'>#{issue_mttr}</label></field>"

    color=LIGHT_GREEN
    if(pr_result)
      if(pr_result[:mttr] > mttr_sla)
        color=LIGHT_CORAL
      end
      text << "<field>#{pr_result[:count]}</field><field><label color='#{color}'>#{pr_result[:mttr].to_s('F')}</label></field>"
    else
      text << "<field>0</field><field><label color='#{color}'>0</label></field>"
    end

    text << "</reporting>\n"

    return text
  end

end
