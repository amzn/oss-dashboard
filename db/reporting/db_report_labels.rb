class LabelDbReporter < DbReporter

  def name()
    return "Label Summary"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows the labels in use, and how many issues + prs, open or closed, are in each. "
  end

  def db_columns()
    return [ ['Label', 'labels'], 'PR/Issue Count']
  end

  def db_report(context, repo, sync_db)
    text=''

    result=sync_db["SELECT l.name, l.color, count(i2l.item_id) as total FROM labels l, item_to_label i2l WHERE i2l.url=l.url AND l.orgrepo=? GROUP BY l.name, l.color ORDER BY total", repo.full_name]
    result.each do |row|
        name=row[:name]
        color=row[:color]
        count=row[:count]
        label = "<label color='#{color}'>#{name}</label>"
        text << "  <reporting class='issue-report' type='LabelDbReporter'><field>#{escape_amp(label)}</field><field>#{count}</field></reporting>"
    end

    return text
  end

end
