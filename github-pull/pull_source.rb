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
require 'octokit'
require 'yaml'

# TODO: Need to use the GitHub API to check the code out, or at the least the private code
# WORKAROUND: Until then, pass in --private and enter credentials or setup SSH key
def pull_source(dashboard_config, client)
  
  organizations = dashboard_config['organizations']
  data_directory = dashboard_config['data-directory']
  scratch_directory="#{data_directory}/scratch"
  unless(File.exist?(scratch_directory))
    Dir.mkdir(scratch_directory)
  end
  
  private=false
  if(ARGV)
    privateMode = (ARGV[0] == '--private')
  end
  
  organizations.each do |owner|
  
      unless(File.exist?("#{scratch_directory}/#{owner}"))
          Dir.mkdir("#{scratch_directory}/#{owner}")
      end
      
      repos = client.organization_repositories(owner)
      repos.each do |repo|
        if repo.fork
          next
        end
        if(privateMode == false and repo.private == true)
          next
        end
        if(privateMode == true and repo.private == false)
          next
        end
        
        repodir="#{scratch_directory}/#{owner}/#{repo.name}"
  
        # Checkout or update - use other script if repo.private
          unless(File.exist?(repodir))
            `git clone -q --depth 1 https://github.com/#{owner}/#{repo.name}.git #{repodir}`
          else
             # Git 1.8.5 solution
             #   `git -C #{repodir} pull -q`
             Dir.chdir(repodir) do
  #             `git pull -q`
  # Hoping fetch and reset will work better than pulling
               remote=`cat .git/config | grep 'remote = ' | sed 's/^.*remote = //'`.strip
               branch=`cat .git/config | grep 'merge = ' | sed 's/^.*merge = refs\\\/heads\\\///'`.strip
               `git fetch -q && git reset -q --hard #{remote}/#{branch}`
           end
        end
      end
  
  end
end
