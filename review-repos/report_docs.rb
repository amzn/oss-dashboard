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

require 'rubygems'
require 'yaml'
require_relative 'reporter'

class DocsReporter < Reporter

  def report(repo, repodir)
    # Look for any text files
    txt  = filename_check(repo, repodir, /\.txt$/, 'DocsReporter', /(LICENSE.txt|NOTICE.txt)/);
    # Look for any md files, this also picks up README.md
    txt << filename_check(repo, repodir, /\.md$/, 'DocsReporter', /(LICENSE.md|NOTICE.md)/);
    return txt
  end

end
