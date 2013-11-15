require 'configliere'
require 'ci/reporter/rake/rspec'      # use this if you're using RSpec
require 'rake/clean'                  # Task to handle cleaning directories/files                

#Built in rake task to clean the content directory of everything
CLEAN.include('content/**')

desc "Start console for app"
task :console do
  exec('bundle exec irb -I. -rapplication')
end

desc "Start app with foreman using developer procfile"
task :start_local_debug do
  exec('bundle exec foreman start -f Procfile.dev -e .env.development')
end

desc "Start app with foreman and thin for internal deployment"
task :start_local do
  exec('bundle exec foreman start -f Procfile.internal -e .env.development')
end

desc "Start app with foreman and thin for internal testing"
task :start_local_dev do
  exec('bundle exec foreman start -f Procfile.internal.dev -e .env.development')
end

desc "Start app with foreman using developer procfile and Heroku database environment"
task :start_local_with_remote_db_debug do
  exec('bundle exec foreman start -f Procfile.dev -e .env')
end

desc "Start app with foreman using developer procfile and Heroku database environment"
task :start_local_with_remote_db do
  exec('bundle exec foreman start -f Procfile.internal -e .env')
end

desc "Upload all the docs to the portal as defined by the local CLOUDANT_URL environement variable."
task :update_local_db do
  ruby "upload_content.rb"
end

desc "Destroy the database.  WARNING!!! - if you do this, your site will be down until you upload new content!"
task :destroy_local_db do
  ruby "drop_database.rb"
end

desc "Destroy the heroku database.  WARNING!!! - if you do this, your site will be down until you upload new content!"
task :destroy_remote_db do
  ENV['CLOUDANT_URL'] = `heroku config:get CLOUDANT_URL`.strip
  Rake::Task["destroy_local_db"].invoke
end

desc "Upload all the docs to the remote portal based on the CLOUDANT_URL value returned by Heroku for this app."
task :update_remote_db do
  # @todo - test, do backticks work on Windows?
  ENV['CLOUDANT_URL'] = `heroku config:get CLOUDANT_URL`.strip
  Rake::Task["update_local_db"].invoke
end

desc "Create the initial heroku environment"
task :initialize_heroku, :app_name do |t, args|
  Settings.read('config/app_config.yaml')
  Settings.resolve!
  # Steps:
  # 1. Test to see if heroku is installed.  If not, give instructions on how to do it - https://toolbelt.heroku.com/
  if command_exists?('heroku')
    puts "Creating the initial heroku app."
    
    app_name = args.app_name
    if (!(app_name.nil?))
      app_name = app_name.strip
      puts "Creating an app with the name: #{app_name}"
      system('heroku apps:create #{app_name}')
    else
      sh 'heroku create'
      puts "You can rename the app later using the command - heroku apps:rename newname"
    end
    
    sh 'heroku addons:add cloudant:oxygen'
    sh 'heroku addons:add memcachier:dev'
    sh 'heroku addons:add newrelic:standard'
    sh 'heroku addons:add papertrail:choklad'
    sh 'heroku config:add RACK_ENV=production'
    puts 'Adding heroku add-on environment variables to the .env file'
    sh 'heroku config -s > .env'
  else
    puts "Install heroku from https://toolbelt.heroku.com"
  end
end
  
# Based on work done at https://github.com/gudleik/twitter-bootstrapped
namespace :bootstrap do
  # desc "One time bootstrap setup"
  task :init do
    if (File.directory?("vendor/twitter-bootstrap") || File.directory?("vendor/fontawesome"))
      puts "The vendor/twitter-bootstrap or vendor/fontawesome directory already exists.  Please remove it."
    else
      `mkdir -p vendor`
      `git submodule add -f https://github.com/twbs/bootstrap.git vendor/twitter-bootstrap`
      `git submodule add -f https://github.com/FortAwesome/Font-Awesome.git vendor/fontawesome`
      `git submodule --quiet update`
      `cd vendor/twitter-bootstrap && git checkout --quiet v2.3.2`
      `cd vendor/fontawesome && git checkout --quiet v3.2.1`
    end
  end

  # We're on v2.3.2 now, and that's where we have to stay
  desc 'Sync twitter bootstrap repo'
  task :update_repo do
    `cd vendor/twitter-bootstrap; git checkout --quiet v2.3.2; git pull --quiet origin master; git checkout --quiet v2.3.2`
  end

  # desc 'Compile the assets. Requires lessc and uglifyjs'
  # To install: npm install -g less uglify-js
  task :make do
    Dir.mkdir("public/bootstrap") unless Dir.exists?("public/bootstrap")
    Dir.mkdir("public/bootstrap/css") unless Dir.exists?("public/bootstrap/css")
    Dir.mkdir("public/bootstrap/js") unless Dir.exists?("public/bootstrap/js")
    Dir.mkdir("public/bootstrap/font") unless Dir.exists?("public/bootstrap/font")
    `cd vendor/twitter-bootstrap && git checkout --quiet v2.3.2`
    `cd vendor/fontawesome && git checkout --quiet v3.2.1`
    `cd ../..`
    if command_exists?('lessc') && command_exists?('uglifyjs')
      `lessc -x less/portal2.less > public/bootstrap/css/portal2.min.css`
      `lessc -x vendor/twitter-bootstrap/less/responsive.less > public/bootstrap/css/bootstrap-responsive.min.css`
      `uglifyjs vendor/twitter-bootstrap/docs/assets/js/bootstrap.js -nc > public/bootstrap/js/bootstrap.min.js`
      cp "vendor/twitter-bootstrap/docs/assets/js/jquery.js", "public/bootstrap/js/jquery.js"
      Dir.glob('vendor/fontawesome/font/*.*').each do |file|
        cp file, "public/bootstrap/font/"
      end
    else
      puts "You need both lessc and uglifyjs on your path to update bootstrap."
    end
  end

  task :uninstall do
    `git submodule deinit -f vendor/twitter-bootstrap`
    `git submodule deinit -f vendor/fontawesome`
    `git rm -f vendor/twitter-bootstrap`
    `git rm -f vendor/fontawesome`
    FileList["vendor/twitter-bootstrap/**/*"].each {|x| File.delete(x)}
    FileList["vendor/fontawesome/**/*"].each {|x| File.delete(x)}
  end

  def command_exists?(cmd)
    if (Config::CONFIG['host_os'].include? "mswin")
      `where.exe #{cmd}`
      $?.success?
    else
      `which #{cmd} 2> /dev/null`
      $?.success?
    end
  end

end

