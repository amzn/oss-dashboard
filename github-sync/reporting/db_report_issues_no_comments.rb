
class NoCommentsDbReporter < DbReporter

  def name()
    return "Open Issues with no comments"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows open issues with no comments. "
  end

  def db_columns()
    return [ ['Issue', 'url'], 'Title', ['Labels', 'labels'] ]
  end

  def db_report(org, sync_db)

    text = ""
    issue_query="SELECT id, item_number, title, org, repo, created_at, updated_at, comment_count FROM items WHERE comment_count=0 AND state='open' AND org=?"
    label_query='SELECT l.url, l.name, l.color FROM labels l, item_to_label itl WHERE itl.url=l.url AND item_id=?'

    issue_data=sync_db.execute(issue_query, [org])
    issue_data.each() do |row|

        url="https://github.com/#{row[4]}/issues/#{row[1]}"
        title=row[2].gsub(/&/, "&amp;").gsub(/</, "&lt;")

        label_data=sync_db.execute(label_query, [row[0]])
        labels=""
        if(label_data)
          label_data.each do |label|
            labelName=label[1].gsub(/ /, '&#xa0;')
            labels << "<label url=\"#{label[0]}\" color='#{label[2]}'>#{labelName}</label>"
          end
        end
        
        text << "  <reporting class='repo-report' repo='#{row[4]}' type='NoCommentsDbReporter'><field>#{url}</field><field>#{title}</field><field>#{labels}</field></reporting>\n"
    end

    return text
  end

end
