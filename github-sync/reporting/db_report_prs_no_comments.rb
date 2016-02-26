
class NoPrCommentsDbReporter < DbReporter

  def name()
    return "Open PRs with no comments"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows open pull requests with no comments. "
  end

  def db_columns()
    return [ ['Pr', 'url'], 'Title', ['Labels', 'labels'] ]
  end

  def db_report(org, sync_db)

    text = ""
    pr_query="SELECT id, pr_number, title, org, repo, created_at, updated_at, comment_count FROM pull_requests WHERE comment_count=0 AND state='open' AND org=?"
    label_query='SELECT l.url, l.name, l.color FROM labels l, item_to_label itl WHERE itl.url=l.url AND item_id=?'

    pr_data=sync_db.execute(pr_query, [org])
    pr_data.each() do |row|

        url="https://github.com/#{row[4]}/pull/#{row[1]}"
        title=row[2].gsub(/&/, "&amp;").gsub(/</, "&lt;")

        label_data=sync_db.execute(label_query, [row[0]])
        labels=""
        if(label_data)
          label_data.each do |label|
            labelName=label[1].gsub(/ /, '&#xa0;')
            labels << "<label url=\"#{label[0]}\" color='#{label[2]}'>#{labelName}</label>"
          end
        end
        
        text << "  <reporting class='issue-report' repo='#{row[4]}' type='NoPrCommentsDbReporter'><field>#{url}</field><field>#{title}</field><field>#{labels}</field></reporting>\n"
    end

    return text
  end

end
