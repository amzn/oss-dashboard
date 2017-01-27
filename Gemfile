#ruby '2.0.0' # any ruby version 1.9+ should be fine

source 'https://rubygems.org'

gem 'rack'

gem 'octokit', '~> 4.6'
gem 'libxml-ruby', '> 0'
gem 'libxslt-ruby', '> 0'
gem 'licensee', '~> 8.7' # CHK TODO this requires cmake and a bunch of gnarly dependencies, as the comment in README.md mentions, should we just patch octokit (hasn't been updated since 2014) to get this now that we can assume github provides this?

gem 'sequel', '~> 4.6'

group :sqlite do
  gem 'sqlite3', '~> 1.3'
end

group :postgres do
  gem 'pg', '~> 0.8'
end
