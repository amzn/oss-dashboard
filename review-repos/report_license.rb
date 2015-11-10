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

  def license_identify(repo, dir)
      begin
        license=Licensee::GitProject.new(dir).license
      rescue ArgumentError
        puts "Error getting license for #{dir}"
        return "      <reporting type='LicenseFilesReporter'>License causes error</reporting>\n"
      end

      if(license)
        return "      <license>#{license.name}</license>\n"
      else
        return "      <reporting type='LicenseReporter'>Unrecognized/Missing License</reporting>\n"
      end
  end

  def report(repo, repodir)
    # Run the license review
    license_identify(repo, repodir);
  end

end
