
class NoPrCommentsDbReporter < DbReporter

  def name()
    return "Open PRs with no comments"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows open pull requests from the community with no comments. "
  end

  def db_columns()
    return [ ['Created', 'date'], ['Pr', 'url'], 'Title', ['Labels', 'labels'] ]
  end

  def db_report(context, org, sync_db)

    text = ""
    pr_query="SELECT pr.id, pr.pr_number, pr.title, pr.org, pr.repo, pr.created_at, pr.updated_at, pr.comment_count FROM pull_requests pr WHERE pr.comment_count=0 AND pr.state='open' AND pr.user_login NOT IN (SELECT m.login FROM member m) AND pr.org=?"
    label_query='SELECT l.url, l.name, l.color FROM labels l, item_to_label itl WHERE itl.url=l.url AND item_id=?'

    pr_data=sync_db.execute(pr_query, [org])
    pr_data.each() do |row|

        url="#{context.github_url}/#{org}/#{row[4]}/pull/#{row[1]}"
        title=row[2].gsub(/&/, "&amp;").gsub(/</, "&lt;")

        label_data=sync_db.execute(label_query, [row[0]])
        labels=""
        if(label_data)
          label_data.each do |label|
            labelName=label[1].gsub(/ /, '&#xa0;')
            labels << "<label url=\"#{escape_amp(label[0])}\" color='#{label[2]}'>#{escape_amp(labelName)}</label>"
          end
        end
        
        text << "  <reporting class='issue-report' repo='#{org}/#{row[4]}' type='NoPrCommentsDbReporter'><field>#{row[5]}</field><field>#{url}</field><field>#{title}</field><field>#{labels}</field></reporting>\n"
    end

    return text
  end

end
