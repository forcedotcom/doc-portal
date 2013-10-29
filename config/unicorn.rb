#worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
worker_processes 2

timeout 15

# We need this for new relic
preload_app true

# This ensures that the TERM signal is translated correctly to the Unicorn model
# See https://devcenter.heroku.com/articles/rails-unicorn
before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

end 

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end
end
