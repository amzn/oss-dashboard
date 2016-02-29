
class NoIssueCommentsDbReporter < DbReporter

  def name()
    return "Open Issues with no comments"
  end

  def report_class()
    return 'issue-report'
  end

  def describe()
    return "This report shows open issues from the community with no comments. "
  end

  def db_columns()
    return [ ['Issue', 'url'], 'Title', ['Labels', 'labels'] ]
  end

  def db_report(org, sync_db)

    text = ""
    issue_query="SELECT i.id, i.issue_number, i.title, i.org, i.repo, i.created_at, i.updated_at, i.comment_count FROM issues i LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN organization o ON i.org=o.login WHERE i.comment_count=0 AND i.state='open' AND i.user_login NOT IN (SELECT m.login FROM member m) AND i.org=?"

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
        
        text << "  <reporting class='issue-report' repo='#{row[4]}' type='NoIssueCommentsDbReporter'><field>#{url}</field><field>#{title}</field><field>#{labels}</field></reporting>\n"
    end

    return text
  end

end
