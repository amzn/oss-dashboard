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

require 'licensee'
require_relative 'reporter'

class LicenseReporter < Reporter

  def name()
    return "License Report"
  end

  def report_class()
    return 'repo-report'
  end

  def describe()
    return "This report shows you the repositories that the <a href='https://github.com/benbalter/licensee'>licensee</a> project GitHub uses is unable to either find or identify. "
  end

  # Allows for context.dashboard_config['LicenseReporter']['license-hashes'] parameter
  # TODO: Implement the custom license hash identification
  def report(context, repo, repodir)

      begin
        project=Licensee::GitProject.new(repodir)
        ignore=project.license # Tests for the error
      rescue ArgumentError
        return "      <reporting class='repo-report' repo='#{repo.full_name}' type='LicenseReporter'>License causes error</reporting>\n"
      end

      unless(project.matched_file)
        return "      <reporting class='repo-report' repo='#{repo.full_name}' type='LicenseReporter'>No License File Found</reporting>\n"
      end

      unless(project.license)
        return "      <reporting class='repo-report' repo='#{repo.full_name}' type='LicenseReporter'><file>#{project.matched_file.filename}</file><message>License unrecognized</message></reporting>\n"
          txt << "      <reporting class='repo-report' repo='#{repo.full_name}' type='#{name}'><file>#{file.to_s[sliceIdx..-1]}</file></reporting>\n"
      else
        return "      <license repo='#{repo.full_name}' file='#{project.matched_file.filename}' confidence='#{project.matched_file.confidence}'>#{project.license.name}</license>\n"
      end
  end

end
