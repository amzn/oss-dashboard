class LabelCountDbReporter < DbReporter

  STANDARD_LABELS=[ 'bug', 'duplicate', 'enhancement', 'help wanted', 'invalid', 'question', 'wontfix' ]

  def name()
    return "Label Count Summary"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the number of open issues for a configured list of standard labels. "
  end

  def labels(context=nil)
    unless(context)
      # Hack to the API to allow the view layer to pass a context in
      context=@context
    end
    if(context.dashboard_config['LabelCountDbReporter'] and context.dashboard_config['LabelCountDbReporter']['labels'])
      return context.dashboard_config['LabelCountDbReporter']['labels']
    else
      return STANDARD_LABELS
    end
  end

  def set_context(context)
    @context=context
  end

  def db_columns()
    cols = [ ['Repository', 'org/repo'] ]
    # TODO: Fix this so it pulls in labels(context) somehow
    cols.concat(labels())
    return cols
  end

  # Allows for context.dashboard_config['LabelCountDbReporter']['labels'] parameter
  def db_report(context, repo, sync_db)

    text="  <reporting class='issue-report' type='LabelCountDbReporter'><field>#{repo.full_name}</field>"

    label_list=labels(context)

    result=sync_db["SELECT name, COUNT(name) AS total FROM labels L, item_to_label I2L, items I WHERE L.url=I2L.url AND I2L.item_id=CAST(I.id AS integer) AND org=? AND repo=? AND name IN ? GROUP BY name", repo.owner.login, repo.name, label_list].to_hash(:name, :total)

    label_list.each do |label|
      total=0
      if(result[label])
        total=result[label]
      end
      text << "<field>#{total}</field>"
    end
    text << "</reporting>\n"

    return text
  end

end
