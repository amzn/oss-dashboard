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

#require_relative 'reporter'

class BinaryReporter < Reporter

  def name()
    return "Binary File Report"
  end

  def describe()
    return "Uses the Linux file command to identify if a file is binary. Empty files and images are filtered out of the list. "
  end

  def report_class()
    return 'repo-report'
  end

  def report(context, repo, repodir)
    txt=""
    sliceIdx=repodir.length + 1
    Dir.glob("#{repodir}/**/*").each do |file|
      unless(File.directory?(file))
        type=`file --brief --mime '#{file}'`
        if(type.include?('charset=binary') and !type.include?('image/') and !type.include?('application/x-empty'))
          txt << "      <reporting class='repo-report' repo='#{repo.full_name}' type='BinaryReporter'><file>#{file.to_s[sliceIdx..-1]}</file></reporting>\n"
        end
      end
    end
    return txt
  end

end
