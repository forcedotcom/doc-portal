require 'bundler'
Bundler.require(:default, (ENV['RACK_ENV'] || :development).to_sym)
require_relative 'config/setup.rb'

# Allow a command-line option to specify one or more languages to upload.
Settings.resolve!

def show_wait_cursor(seconds,fps=10)
  chars = %w[| / - \\]
  delay = 1.0/fps
  (seconds*fps).round.times{ |i|
    print chars[i % chars.length]
    sleep delay
    print "\b"
  }
end

puts "This will delete your database and make your app unusable.  You have 10 seconds to stop this command."
show_wait_cursor(5)
puts "5 more seconds ... are you sure?"
show_wait_cursor(5)
puts "Okay, here we go!"
db= set_db()
db.delete!
