require 'rake'
require 'yaml'
require_relative 'util.rb'

desc 'collect data from github.com and output to database'
task :doit do # not sure this is the right name
  sh sprintf('ruby refresh-dashboard.rb --ghconfig %s %s', GIT_CONFIG, DB_CONFIG)
end

desc 'bootstrap postgres database'
task :bootstrap do # this is not the right name
  init_postgres_db(YAML.file_load(DB_CONFIG))
end