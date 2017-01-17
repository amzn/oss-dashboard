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

  def db_report(context, org, sync_db)
    
    query="SELECT l.name, l.color, count(i2l.item_id) FROM labels l, item_to_label i2l WHERE i2l.url=l.url AND l.orgrepo LIKE ? GROUP BY l.name, l.color ORDER BY l.name"
    like_term="#{org}/%" # CHK TODO need to take this into account
    text=''

    result=sync_db[query]
    result.each do |row|
        name=row[0]
        color=row[1]
        count=row[2]
        label = "<label color='#{color}'>#{name}</label>"
        text << "  <reporting class='issue-report' type='LabelDbReporter'><field>#{label}</field><field>#{count}</field></reporting>"
    end

    return text
  end

end
