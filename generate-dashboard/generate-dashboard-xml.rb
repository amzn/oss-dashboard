# Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../review-repos/reporter_runner'
require_relative '../db/reporting/db_reporter_runner'

def escape_for_xml(text)
  return text ? text.tr("\b", '').gsub(/&/, '&amp;').gsub(/</, '&lt;') : text
end

def generate_report_metadata(context, metadata, tag)
  metadata << "  <#{tag}s>\n"
  report_instances=get_reporter_instances(context.dashboard_config)
  report_instances.each do |report_obj|
    if(report_obj.report_class() == tag)
      metadata << "    <report key='#{report_obj.class.name}' name='#{report_obj.name}'><description>#{report_obj.describe}</description></report>\n"
    end
  end
  db_report_instances=get_db_reporter_instances(context.dashboard_config)
  db_report_instances.each do |report_obj|
    if(report_obj.report_class() == tag)
      metadata << "    <report key='#{report_obj.class.name}' name='#{report_obj.name}'><description>#{report_obj.describe}</description>"

      # This is an API hack to provide the context to db_column without changing that API
      report_obj.set_context(context) if report_obj.respond_to? :set_context

      report_obj.db_columns.each do |db_column|
        if(db_column.kind_of?(Array))
          metadata << "<column-type type='#{db_column[1]}'>#{escape_for_xml(db_column[0])}</column-type>"
        else
          metadata << "<column-type type='text'>#{escape_for_xml(db_column)}</column-type>"
        end
      end
      metadata << "</report>\n"
    end
  end
  metadata << "  </#{tag}s>\n"
end

def generate_metadata_header(context)
  organizations = context.dashboard_config['organizations']
  logins = context.dashboard_config['logins']

  metadata = " <metadata>\n"
  metadata << "  <navigation>\n"
  if(organizations)
    if(organizations.length > 1)
      metadata << "    <organization>AllOrgs</organization>\n"
    end
    organizations.each do |org|
      metadata << "    <organization>#{org}</organization>\n"
    end
  end
  if(logins)
    if(logins.length > 1)
      metadata << "    <login>AllLogins</login>\n"
    end
    logins.each do |login|
      metadata << "    <login>#{login}</login>\n"
    end
  end
  metadata << "  </navigation>\n"

  # Which User Management Reports are configured?
  generate_report_metadata(context, metadata, 'user-report')

  # Which Repo Reports are configured?
  generate_report_metadata(context, metadata, 'repo-report')

  # Which Issue Reports are configured?
  generate_report_metadata(context, metadata, 'issue-report')

  metadata << "  <run-metrics refreshTime='#{context[:START_TIME]}' generationTime='#{DateTime.now}' startRateLimit='#{context[:START_RATE_LIMIT]}' endRateLimit='#{context[:END_RATE_LIMIT]}' usedRateLimit='#{context[:USED_RATE_LIMIT]}'/>\n"

  metadata << " </metadata>\n"
  return metadata
end
