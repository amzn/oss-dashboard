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
require 'yaml'
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
      rescue Rugged::ReferenceError
        return "      <reporting class='repo-report' repo='#{repo.full_name}' type='LicenseReporter'>License causes error</reporting>\n"
      end

      unless(project.matched_file)
        return "      <reporting class='repo-report' repo='#{repo.full_name}' type='LicenseReporter'>No License File Found</reporting>\n"
      end

      if(project.matched_file.confidence == '100')
        return "      <license repo='#{repo.full_name}' file='#{project.matched_file.filename}' confidence='#{project.matched_file.confidence}'>#{project.license.name}</license>\n"
      end

      if(project.matched_file.hash)
        if(context.dashboard_config['LicenseReporter'] and context.dashboard_config['LicenseReporter']['license-hashes'])
          license_hashes_file=context.dashboard_config['LicenseReporter']['license-hashes']
          license_hashes = YAML.load(File.read(license_hashes_file))
  
          license_hashes['license-hashes'].each do |custom_hash|
            if(project.matched_file.hash == custom_hash['hash'])
              return "      <license repo='#{repo.full_name}' file='#{project.matched_file.filename}' confidence='100'>#{custom_hash['name']}</license>\n"
            end
          end
        end
      end

      if(project.license)
        return "      <license repo='#{repo.full_name}' file='#{project.matched_file.filename}' confidence='#{project.matched_file.confidence}'>#{project.license.name}</license>\n"
      else
        return "      <reporting class='repo-report' repo='#{repo.full_name}' type='LicenseReporter'><file>#{project.matched_file.filename}</file><message>License unrecognized (hash:#{project.matched_file.hash})</message></reporting>\n"
      end

  end

end
