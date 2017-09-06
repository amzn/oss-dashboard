require 'json'

# Convert a Sequel array of hash to an array of array
def to_array_of_arrays(dataset)
  cols = dataset.columns
  ret = []
  dataset.all do |row_hash|
    row_array = []
    cols.map { |col| row_array << row_hash[col] }
    ret << row_array
  end
  return ret
end

# Cumulate field 0 of an array of array
def cumulative(arr_of_arr) 
  sum=0
  arr_of_arr.map { |x| sum += x[1]; [x[0], sum] }
end

# This function ensures that N data arrays have the same x-axis ticks
# It currently assumes cumulative; that is it copies over from the previous value
def fill_array_of_arrays(array)
  hashes=Array.new
  array.each_with_index do |sub_array, idx|
    hashes[idx]=sub_array.to_h
  end

  keys=Array.new
  hashes.map { |hash| keys.concat(hash.keys) }
  keys=keys.uniq.sort

  new_arrays=Array.new(array.length) { Array.new }

  hashes.each_with_index do |hash, idx|
    last=0
    keys.each do |key|
      if(hash[key])
        new_arrays[idx] << [key, hash[key]]
        last = hash[key]
      else
        new_arrays[idx] << [key, last]
      end
    end
  end

  return new_arrays
end

# Save the JSON data
def save(context, filename, hash)
  www_directory = context.dashboard_config['www-directory']

  path="#{www_directory}/json-data/#{filename}.json"
  f = open(path, 'w')
  f.puts(JSON.pretty_generate(hash))
  f.close
end

# Load the JSON data
def load(context, filename)
  www_directory = context.dashboard_config['www-directory']

  path="#{www_directory}/json-data/#{filename}.json"

  if(File.exists?(path))
    txt=File.read(path)
    return JSON.parse(txt)
  else
    return nil
  end
end

# TODO: Figure out how to output team+merged data separately
# Merged is a case of combining the json files neh?
# Teams means having these values for repositories. Tricky.
# Maybe need to redo the team notion into the idea that there are N dashboards 
#   where a dashboard is a set of repositories. Generate each repositories 
#   dash-xml first, then build dashboards out of them.
#   Team + Organization are just special containers. The XSLT can be standard for <repos>
#   and then have customer Overview sections if <teams> or <organization> blocks.
#   Reports are currently separate from <repos>. Need to figure out what would happen 
#   there. repo-reports + issue-reports are easy; merge in with repos. 
#   user-reports less easy as those are more specific to Team/Organizations. 
#   perhaps simplest to ditch user-reports. Everything becomes about repos, not orgs/teams.
# This allows for custom dashboard collections.



def generate_json_data(context)

  organizations = context.dashboard_config['organizations+logins']
  www_directory = context.dashboard_config['www-directory']

  sync_db = get_db_handle(context.dashboard_config)

  organizations.each do |org|
    context.feedback.print "  #{org} "


    unless(File.exists?("#{www_directory}/json-data/"))
      Dir.mkdir("#{www_directory}/json-data/")
    end
    unless(File.exists?("#{www_directory}/json-data/#{org}/"))
      Dir.mkdir("#{www_directory}/json-data/#{org}/")
    end

    # Output the data for the default dashboard charts
    repos=sync_db["SELECT name FROM repository WHERE org=?", org]
    repos.each do |repoRow|
      repoName = repoRow[:name]

      ############ repoCount ############ 
      # TODO: Need to fill in missing data
      # TODO: Aesthetics on this chart, nice to have an empty year to start with

      repo_data=sync_db["SELECT EXTRACT(year FROM created_at)::integer AS year, private FROM repository WHERE org=? AND name=?", org, repoName].first
      # TODO: Use Events API to determine when something changed from private->public?
      current_year = Date.today.year
      data=Array.new
      data << [repo_data[:year]-1, 0]
      repo_data[:year].upto(current_year) do |year|
        data << [year, 1]
      end

      privateCount=repo_data[:private] ? data : []
      publicCount=repo_data[:private] ? [] : data

      filledData=fill_array_of_arrays( [privateCount, publicCount] )
      save(context, "#{org}/#{repoName}-repoCount", 
          { 'datasets' => [ { 'data' => filledData[0], 'label' => 'private'},
                            { 'data' => filledData[1], 'label' => 'public'}
          ] } )
          

      ############ issueCount ############
      # Yearly Issues Opened
      openedIssues=cumulative(to_array_of_arrays(sync_db["SELECT EXTRACT(YEAR FROM created_at) as year, COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoName}' AND state='open' GROUP BY year ORDER BY year"]))
      closedIssues=cumulative(to_array_of_arrays(sync_db["SELECT EXTRACT(YEAR FROM closed_at) as year, COUNT(*) FROM issues WHERE org='#{org}' AND repo='#{repoName}' AND state='closed' GROUP BY year ORDER BY year"]))

      unless(openedIssues.empty? and closedIssues.empty?)
        filledData=fill_array_of_arrays( [closedIssues, openedIssues] )
        save(context, "#{org}/#{repoName}-issueCount", 
            { 'datasets' => [ { 'data' => filledData[0], 'label' => 'closed' }, { 'data' => filledData[1], 'label' => 'open' } ] } )
      end

      ############ issueTimeToClose ############

      ranges=[
               [1, '1 hour', 0, 0.0417],
               [2, '3 hours', 0.0417, 0.125],
               [3, '9 hours', 0.125, 0.375],
               [4, '1 day', 0.375, 1],
               [5, '1 week', 1, 7],
               [6, '1 month', 7, 30],
               [7, '1 quarter', 30, 90],
               [8, '1 year', 90, 365],
               [9, 'over a year', 365, 10000000]
             ]

      data=Array.new
      ranges.each do |range|
        # 355 days
        ageCount=sync_db["SELECT COUNT(*) FROM issues WHERE to_char(closed_at::date,'J')::integer - to_char(created_at::date,'J')::integer > ? AND to_char(closed_at::date,'J')::integer - to_char(created_at::date,'J')::integer <= ? AND org='#{org}' AND repo='#{repoName}' AND state='closed'", range[2], range[3]].first[:count]
        data << [range[0], ageCount]
      end
      save(context, "#{org}/#{repoName}-issueTimeToClose", 
            { 'datasets' => [ { 'data' => data, 'label' => 'Tickets' } ] } )

      ############ issueCommunityPie ############
      # TODO: This (and PR below) appears to be a slow query
      projectIssueCount=sync_db["SELECT COUNT(DISTINCT(i.id)) FROM issues i LEFT OUTER JOIN organization o ON i.org=o.login LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN member m ON otm.member_id=m.id WHERE i.org=? AND i.repo=? AND m.login=i.user_login", org, repoName].first[:count]
      communityIssueCount=sync_db["SELECT COUNT(DISTINCT(i.id)) FROM issues i LEFT OUTER JOIN organization o ON i.org=o.login LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id WHERE i.org=? AND i.repo=? AND i.user_login NOT IN (SELECT m.login FROM member m)", org, repoName].first[:count]
      save(context, "#{org}/#{repoName}-issueCommunityPie", 
            { 'datasets' => [ 
                    { 'data' => projectIssueCount, 'label' => 'Project' },
                    { 'data' => communityIssueCount, 'label' => 'Community' }
            ] } )

      ############ pullRequestCount ############
      # Yearly PRs Opened
      openedPRs=cumulative(to_array_of_arrays(sync_db["SELECT EXTRACT(YEAR FROM created_at) as year, COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoName}' AND state='open' GROUP BY year ORDER BY year"]))
      closedPRs=cumulative(to_array_of_arrays(sync_db["SELECT EXTRACT(YEAR FROM closed_at) as year, COUNT(*) FROM pull_requests WHERE org='#{org}' AND repo='#{repoName}' AND state='closed' GROUP BY year ORDER BY year"]))

      unless(openedPRs.empty? and closedPRs.empty?)
        filledData=fill_array_of_arrays( [closedPRs, openedPRs] )
        save(context, "#{org}/#{repoName}-pullRequestCount", 
            { 'datasets' => [ { 'data' => filledData[0], 'label' => 'closed' }, { 'data' => filledData[1], 'label' => 'open' } ] } )
      end

      ############ prTimeToClose ############
      data=Array.new
      ranges.each do |range|
        # 355 days
        ageCount=sync_db["SELECT COUNT(*) FROM pull_requests WHERE to_char(closed_at::date,'J')::integer - to_char(created_at::date,'J')::integer > ? AND to_char(closed_at::date,'J')::integer - to_char(created_at::date,'J')::integer <= ? AND org='#{org}' AND repo='#{repoName}' AND state='closed'", range[2], range[3]].first[:count]
        data << [range[0], ageCount]
      end
      save(context, "#{org}/#{repoName}-prTimeToClose", 
            { 'datasets' => [ { 'data' => data, 'label' => 'Tickets' } ] } )

      ############ prCommunityPie ############
      projectPrCount=sync_db["SELECT COUNT(DISTINCT(pr.id)) FROM pull_requests pr LEFT OUTER JOIN organization o ON pr.org=o.login LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id LEFT OUTER JOIN member m ON otm.member_id=m.id WHERE pr.org=? AND pr.repo=? AND m.login=pr.user_login", org, repoName].first[:count]
      communityPrCount=sync_db["SELECT COUNT(DISTINCT(pr.id)) FROM pull_requests pr LEFT OUTER JOIN organization o ON pr.org=o.login LEFT OUTER JOIN organization_to_member otm ON otm.org_id=o.id WHERE pr.org=? AND pr.repo=? AND pr.user_login NOT IN (SELECT m.login FROM member m)", org, repoName].first[:count]
      save(context, "#{org}/#{repoName}-prCommunityPie", 
            { 'datasets' => [ 
                    { 'data' => projectPrCount, 'label' => 'Project' },
                    { 'data' => communityPrCount, 'label' => 'Community' }
            ] } )

      context.feedback.print '.'
    end
    context.feedback.print "\n"
  end

  # TODO: Output the json-data for the report API

end

def generate_json_for_dashboard(context, dashboard_name, repos)
  chart_add(context, dashboard_name, repos, 'repoCount')
  chart_add(context, dashboard_name, repos, 'issueCount')
  chart_add(context, dashboard_name, repos, 'pullRequestCount')
  chart_add(context, dashboard_name, repos, 'issueTimeToClose')
  chart_add(context, dashboard_name, repos, 'prTimeToClose')
  chart_add(context, dashboard_name, repos, 'issueCommunityPie')
  chart_add(context, dashboard_name, repos, 'prCommunityPie')
end

# Merge json data for a set of repos
# ASSUMES natural sort order for the x axis
# ASSUMES _merging_ means adding
def chart_add(context, dashboard_name, repos, chart)

  unless(repos)
    return
  end

  new_data=Hash.new
  label_order=nil

  repos.each do |repoFullName|
    hash=load(context, "#{repoFullName}-#{chart}")
    unless(hash)
      next
    end

    # Remember the order of the labels
    unless(label_order)
      label_order=Array.new
      hash['datasets'].each do |dataset|
        label=dataset['label']
        label_order << label
      end
    end

    # Aggregate/sum the data
    hash['datasets'].each do |dataset|
      label=dataset['label']
      data=dataset['data']

      if(data.is_a? Array)
        unless(new_data[label])
          new_data[label]=Hash.new(0)
        end

        data.each do |pair|
          new_data[label][pair[0]]+=pair[1]
        end
      else
        # PieChart only has 1 data axis
        unless(new_data[label])
          new_data[label]=0
        end

        new_data[label]+=data
      end
    end

  end

  unless(label_order)
    return
  end

  new_datasets={'datasets' => [] }
  label_order.each do |label|
    if(new_data[label].is_a? Hash)
      # HACK. By using sort, we assume the chart naturally sorts
      new_datasets['datasets'] << { 'data' => new_data[label].sort { |a,b| a[0] <=> b[0] },
                              'label' => label
                          }
    else
      new_datasets['datasets'] << { 'data' => new_data[label], 'label' => label }
    end
  end

  save(context, "#{dashboard_name}-#{chart}", new_datasets )
  
end
