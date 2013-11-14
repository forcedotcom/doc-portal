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


# Based on
# https://github.com/ai/r18n/blob/master/sinatra-r18n/lib/sinatra/r18n.rb
# 06/20/2013

module Sinatra
  module R18n
    def self.registered(app)
      app.helpers ::R18n::Helpers
      app.set :default_locale, Proc.new { ::R18n::I18n.default }
      app.set :translations,   Proc.new { ::R18n.default_places }

      ::R18n.default_places { File.join(app.root, 'i18n/') }

      app.before do
        ::R18n.clear_cache! if self.class.development?

      end
    end
  end

  register R18n
end
