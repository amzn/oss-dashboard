# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'octokit'

class DashboardContext < Hash

  attr_reader :feedback, :dashboard_config, :client
  OCTOKIT_API_ENDPOINT = ENV['OCTOKIT_API_ENDPOINT']

  # parameters:  feedback: output stream, dashboard_config: yaml hash, client: octokit client
  def initialize(feedback, dashboard_config, client)
    @feedback=feedback
    @dashboard_config=dashboard_config
    @client=client

    owners=Array.new
    if(dashboard_config['organizations'])
      owners.concat(dashboard_config['organizations'])
    end
    if(dashboard_config['logins'])
      owners.concat(dashboard_config['logins'])
    end

    if(dashboard_config['repositories'])
      # default to empty array
      @repo_hash=Hash.new { |h, k| h[k] = Array.new }
      dashboard_config['repositories'].each do |orgrepo|
        if(orgrepo.count('/') == 1)
          (org, repo) = orgrepo.split('/')
          @repo_hash[org] << repo
        end
      end
      owners.concat(@repo_hash.keys)
    end

    dashboard_config['organizations+logins']=owners
  end

  def login?(login)
    if(dashboard_config['logins'])
      return dashboard_config['logins'].include?(login)
    else
      return false
    end
  end

  def org?(org)
    if(dashboard_config['organizations'])
      return dashboard_config['organizations'].include?(org)
    else
      return false
    end
  end

  def github_com?
    if(OCTOKIT_API_ENDPOINT)
      return false
    else
      return true
    end
  end

  def github_url
    if(github_com?)
      return 'https://github.com'
    else
      # https://github.url/api/v3/
      return OCTOKIT_API_ENDPOINT.sub(%r{/api/v3/?}, '')
    end
  end

  def private_access?(org)
    if(dashboard_config['private-access'])
      return dashboard_config['private-access'].include?(org)
    else
      return false
    end
  end

  def hide_private_repositories?
    return dashboard_config['hide-private-repositories']==true
  end

  def repositories(account)
    if(login?(account))
      return client.repositories(account)
    elsif(@repo_hash[account])
      repos = client.organization_repositories(account)
      filtered_repos=Array.new
      repos.each do |repo|
        if(@repo_hash[account].include?(repo.name))
          filtered_repos << repo
        end
      end
      return filtered_repos
    else
      return client.organization_repositories(account)
    end
  end

end
