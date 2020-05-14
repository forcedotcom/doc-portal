source "https://rubygems.org"
ruby "2.1.2"

gem 'sinatra', '>= 2.0.0', require: 'sinatra/base'
gem 'bundler', '~> 1.1'
gem 'haml'
gem 'thin', '>= 1.7.0'
gem 'couchrest'
gem 'json'
gem 'sinatra-r18n', '>= 2.0.3', require: 'sinatra/r18n'
gem 'sinatra-contrib', '>= 2.0.0', require: 'sinatra/reloader'
gem 'configliere'
gem 'dalli'
gem "memcachier"
gem 'foreman'
gem "nokogiri"
gem "htmlentities"
gem 'newrelic_rpm'
gem 'will_paginate', require: ['will_paginate', 'will_paginate/array']
gem 'unicorn', '>= 4.8.3'
gem 'logging'
gem 'ci_reporter_rspec'

group :development do
  gem 'better_errors', '>= 2.1.1'
  gem 'binding_of_caller'
  gem 'rake'
  gem 'shotgun', '>= 0.9'
  gem 'yard'
  gem 'yard-sinatra'
end

group :test do
  gem 'rspec'
  gem 'rack-test', '>= 0.6.3', require: 'rack/test'
  gem 'byebug'
  gem 'simplecov', :require => false
  gem 'simplecov-rcov'
  gem 'memcache_mock'
end
