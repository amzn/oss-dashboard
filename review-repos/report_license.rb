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

  def describe()
    return "This report shows you the repositories that the <a href='https://github.com/benbalter/licensee'>licensee</a> project GitHub uses is unable to either find or identify. "
  end

  def license_identify(repo, dir)
      begin
        project=Licensee::GitProject.new(dir)
        ignore=project.license # Tests for the error
      rescue ArgumentError
        return "      <reporting type='LicenseReporter'>License causes error</reporting>\n"
      end

      unless(project.matched_file)
        return "      <reporting type='LicenseReporter'>No License File Found</reporting>\n"
      end

      unless(project.license)
        return "      <reporting type='LicenseReporter'><file>#{project.matched_file.filename}</file><message>License unrecognized</message></reporting>\n"
          txt << "      <reporting type='#{name}'><file>#{file.to_s[sliceIdx..-1]}</file></reporting>\n"
      else
        return "      <license file='#{project.matched_file.filename}' confidence='#{project.matched_file.confidence}'>#{project.license.name}</license>\n"
      end
  end

  def report(repo, repodir)
    # Run the license review
    license_identify(repo, repodir);
  end

end
