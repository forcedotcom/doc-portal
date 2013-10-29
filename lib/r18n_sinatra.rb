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
