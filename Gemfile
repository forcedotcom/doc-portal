source "https://rubygems.org"
ruby "2.1.2"

gem 'sinatra', require: 'sinatra/base'
gem 'bundler', '~> 1.1'
gem 'haml'
gem 'thin'
gem 'couchrest'
gem 'json'
gem 'sinatra-r18n', require: 'sinatra/r18n'
gem 'sinatra-contrib', require: 'sinatra/reloader'
gem 'configliere'
gem 'dalli'
gem "memcachier"
gem 'foreman'
gem "nokogiri"
gem "htmlentities"
gem 'newrelic_rpm'
gem 'will_paginate', require: ['will_paginate', 'will_paginate/array']
gem 'unicorn'
gem 'logging'
gem 'ci_reporter_rspec'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rake'
  gem 'shotgun'
  gem 'yard'
  gem 'yard-sinatra'
end

group :test do
  gem 'rspec'
  gem 'rack-test', require: 'rack/test'
  gem 'byebug'
  gem 'simplecov', :require => false
  gem 'simplecov-rcov'
  gem 'memcache_mock'
end
