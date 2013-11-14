#Copyright (c) 2013,salesforce.com 
#All rights reserved.

#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions
#are met:

#Redistributions of source code must retain the above copyright
#notice, this list of conditions and the following disclaimer.

#Redistributions in binary form must reproduce the above copyright
#notice, this list of conditions and the following disclaimer in the
#documentation and/or other materials provided with the distribution.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
#OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
#WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#POSSIBILITY OF SUCH DAMAGE.


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
