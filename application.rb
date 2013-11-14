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
require_relative 'lib/r18n_sinatra.rb'
require_relative 'lib/will_paginate_renderer.rb'
require_relative 'helpers/helpers.rb'
require_relative 'helpers/haml_helpers.rb'
# Need to override some issues with the locales for R18N
require_relative 'lib/zh-tw.rb'
require_relative 'lib/zh-cn.rb'

module SFDC
  class Portal < Sinatra::Base
    # Include our helper methods
    helpers Sinatra::CouchPortalHelpers
    helpers HamlHelpers

    # Set up I18N
    register Sinatra::R18n
    helpers R18n::Helpers
    R18n::I18n.default = Settings[:DEFAULT_LOCALE].nil? ? "en-us" : Settings[:DEFAULT_LOCALE]

    register WillPaginate::Sinatra
        
    include Rack::Utils
    
    # Compress the files
    use Rack::Deflater

    ### Caching
    set :static, true
    set :static_cache_control, [:public, {:max_age => 175000, :expires => 500}]
    set :cache, Dalli::Client.new
    set :enable_cache, true rescue set :enable_cache, false
    set :short_ttl, 400
    set :long_ttl, 4600

    configure do
      ### Setup the directories
      # Explicitly set root
      set :root, File.dirname(__FILE__)
      # Location of all static files
      set :public_folder, Proc.new { File.join(root, "public") }
      # Set the translation dir
      set :translations, Proc.new { File.join(root, 'i18n/') }

      # Using haml for the views
      set :haml, :format=> :html5, :ugly => true

      # Turn on logging
      set :logging, true

      # Set default topic
      set :default_topic, Settings[:DEFAULT_TOPIC].nil? ? "" : Settings[:DEFAULT_TOPIC]

      # Define the database
      # We only want to set the database once, so we do it here.
      set :couchdb, set_db()

      # Determine which kind of search view we canuse.
      set :view, set_view()

      before do
        expires 500, :public, :must_revalidate
        @version = set_version()

        # Take the database info from the settings.
        @db = settings.couchdb

        # Define the view
        @view = settings.view

        # Just in case a route doesn't call this and it's needed
        @locale = set_locale('')
      end

    end # End generic configure block

    # Things to do on production, not development, environments
    configure :production do
      #if the login is *explicitly* disabled, then don't go into this block
      unless ("false".eql? ENV["LOGIN_REQUIRED"])
        # Authentication
        use Rack::Auth::Basic, "Restricted Area" do |username, password|
          [username, password] == [Settings[:LOGIN_USERNAME], Settings[:LOGIN_PASSWORD]]
        end
      end
      require 'newrelic_rpm'
    end

    # Things to do in development, not in production, environments
    configure :development do
      # Use reloader, not shotgun, for debugging, so we can get BetterErrors
      register Sinatra::Reloader
      # These helpers sometimes don't auto-load
      also_reload 'helpers/haml_helpers.rb'
      also_reload 'helpers/helpers.rb'
      also_reload 'helpers/general_helpers.rb'
      use BetterErrors::Middleware
      BetterErrors.application_root = File.expand_path("..", __FILE__)
    end
    
    #Configurations for testing
    configure :test do
      set :cache, MemcacheMock.new
    end

    # Routes start here     

    # Ignores
    # Ignore all help.css calls
    # @todo - get rid of help.css in the HTML
    get '*help.css' do
      ""
    end

    get '/' do
      resolve_landing_page_or_default_topic()
    end
    
    #Index pages should go to the default landing page of the appropriate language
    get '/:locale/:version/*index.htm' do
      redirect_to_default_topic(params[:locale], params[:version])
    end
    
    #Index pages should go to the default landing page of the appropriate language
    get '/:locale/*index.htm' do
      redirect_to_default_topic(params[:locale], Settings[:CURRENT_VERSION])
    end

    #Index pages without any content should go there
    get '*index.htm' do
      redirect_to_default_topic(Settings[:DEFAULT_LOCALE], params[:version])
    end

    
    # Handle results from search
    # @todo - Need to add versioning and locale to the search
    get '/:locale/:version/search' do
      @locale = set_locale(params[:locale])
      @query = params[:query]
      @version = set_version(params[:version])
      @display_facets ||= ('yes'.eql?(params[:facets]) ? true : false)
      begin
        search_result = search(@db, @locale, @version, @query)
        @search = JSON.parse(%Q[#{search_result}])
        @results = @search['rows']
        haml :results
      rescue => e
        puts "Search failed!"
        @results = nil
        puts e.class
        puts e.message
        haml :'404'
      end
    end

    # Get for HTML files with version and lang-locale
    # Example - http://localhost:9393/en-us/data_loader/command_line_chapter.htm
    get '/:locale/:version/*/:topic.:format' do      
      # If the URL does not end in .htm, .html, pass it off to the
      # generic handler.
      pass unless params[:format].include? 'htm'

      # Set all the required variables based on the URL
      format = ".#{params[:format]}"
      @locale = set_locale(params[:locale])
      version = set_version(params[:version])
      directory = params[:splat][0]
      directory_array = params[:splat][0].split("/")
      deliverable = directory_array[0] #the deliverable name
      set_content_type(format)
      topicname = get_topic_name(params[:splat][0], params[:topic], format)
      @urlTopic = params[:topic] + format #the full topic name
      
      # Assume that we have all the info to correctly get the topic
      # and get it.  If that get fails, try to get it with the default
      # lang-local pair.
      # Why don't we validate the URL?  Because we'd have to create a list of
      # "acceptable" version and locale strings.
      begin
        query_topic(@db, @locale, version, topicname, deliverable)
        haml :topic
      rescue => e
        begin
          # Fallback to DEFAULT_LOCALE
          if(@locale != Settings[:DEFAULT_LOCALE])
          then
            STDERR.puts "Couldn't get the content for #{topicname}, trying with default locale: #{Settings[:DEFAULT_LOCALE]}"
            @locale = Settings[:DEFAULT_LOCALE]
            query_topic(@db, @locale, version, topicname, deliverable)
            haml :topic
          else
            # @todo Can we change the homepage link on the 404 page to
            # use the default topic instead of index?
            puts e.class
            puts e.message
            haml :'404'
          end
        rescue => e
          puts "Something is really fubar'd in the version topic get."
          puts e.class
          puts e.message
          haml :'404'
        end
      end
    end

    # Get something that isn't an html file
    get '/:locale/:version/*/:topic.:format' do
      # Based on the reference, return the image
      locale = set_locale(params[:locale])
      version = set_version(params[:version])
      topic = params[:topic]
      format = ".#{params[:format]}"
      set_content_type(format)
      begin
        topicname = get_topic_name(params[:splat][0], topic, format)
        STDOUT.puts "Getting file with selected version and locale. Getting: #{topicname}"
        return get_attachment(@db, locale, version, topicname)
      rescue 
        begin
          # Nope, didn't find that attachment.
          # Assume that there's no version, then assume there's no
          # locale or version, then bail.
          topicname = get_topic_name("#{params[:version]}/#{params[:splat][0]}", topic, format)
          STDERR.puts "Couldn't get that non-html document, trying default version - #{topicname}"
          return get_attachment(@db, locale, Settings[:CURRENT_VERSION], topicname)
        rescue
          # Nope, didn't find that attachment.
          # Let's set the locale to default and try again.
          topicname = get_topic_name("#{params[:splat][0]}", topic, format)
          STDERR.puts "Couldn't get that non-html document, trying default locale and version - #{topicname}"
          return get_attachment(@db, Settings[:DEFAULT_LOCALE], Settings[:CURRENT_VERSION], topicname)
        end
      rescue => e
        STDERR.puts "Could not find the non-html file #{param[:locale]}/#{params[:version]}/#{params[:splat][0]}/#{topic}#{format}"
        return nil
      end
    end

    # @todo - Figure out how to make this work if the content isn't in a subdirectory.
    # Topic without a version
    get '/*/*/:topic.:format' do
      # If the first param has a - then it's a locale, so handle it
      # here.  Otherwise, pass it on to the next route.      
      pass unless /^..-..$/.match(params[:splat][0])
      call_topic(params[:splat][0], Settings[:CURRENT_VERSION], "#{params[:splat][1]}/#{params[:topic]}.#{params[:format]}")
    end

    # Topic without a locale
    get '/*/*/:topic.:format' do
      @locale = set_locale('')
      call_topic(@locale, params[:splat][0], "#{params[:splat][1]}/#{params[:topic]}.#{params[:format]}")
    end

    # @todo - Figure out how to make this work if the content isn't in a subdirectory.
    # Topic without a version
    get '/*/:topic.:format' do
      call_topic(Settings[:DEFAULT_LOCALE], Settings[:CURRENT_VERSION], "#{params[:splat].join("/")}/#{params[:topic]}.#{params[:format]}")
    end
    
    # Search without a version
    get '/:locale/search' do
      status,headers,body = call env.merge("PATH_INFO" => "/#{params[:locale]}/#{Settings[:CURRENT_VERSION]}/search")
      [status,headers,body]
    end
    
    #Load test the site with blitz/io
    get "/#{Settings[:BLITZ_IO_IDENTIFIER]}" do
      "42"
    end
    
    #Route for urls of the form /lang-locale/version/deliverable or /lang-locale/deliverable
    get %r{^/(([^/)]+/?){1,3})$} do
      declared_params = params[:captures].first.split("/")
      #the lang-locale, version, deliverable was declared
      if (declared_params.length == 3)
        redirect_to_default_topic(declared_params[0], declared_params[1], declared_params[2])
      elsif (declared_params.length == 2)
        #the lang-locale and deliverable was declared
        redirect_to_default_topic(declared_params[0], set_version(), declared_params[1])
      elsif (declared_params.length == 1)
        #only the lang-locale was declared
        resolve_landing_page_or_default_topic(declared_params[0])
      else
        haml :'404'
      end
    end

    # Error pages
    not_found do
      haml :'404'
    end
    error do
      puts "500 error! #{request.env['sinatra_error']}"
      haml :'500'
    end
    
    #Query the topic and table of contents
    def query_topic(db, locale, version, topicname, deliverable)
      id = get_topic_or_image_id(locale, version, topicname)
      begin
        #do we have a multi-deliverable portal?, get the deliverable title
        if (Settings[:LANDING_PAGE].eql? "true")
          doc = get_document_by_id(db, id)
          @topic = doc['body_content']
          @deliverable_title = doc['deliverable_title']
        else
          @topic = get_html_body(db, locale, version, topicname)
        end
        begin
          @toc = get_toc(@db, locale, version, deliverable)
        rescue => e
          puts "Failed to locate the table of content for #{@locale}, #{version}, #{deliverable}"
          puts e.class
          puts e.message
          raise
        end
        begin
          # TODO Potential performance issue.  We're now doing three database calls per
          # topic.  Could we put all this metadata on each topic
          # document instead?  What about the ToC though?
          id = get_deliverable_metadata_id(@locale, version, deliverable)
          meta_doc = get_document_by_id(@db, id)
          @pdf_url = meta_doc['pdf_url']
        rescue
          @pdf_url=""
        end
      rescue => e
        puts "Failed to locate topic with id '#{id}'"
        puts e.class
        puts e.message
        raise
      end
    end
    
    #Get the full topic name from the URL
    def get_topic_name(topic_path, topic, ext)
      return "#{topic_path}/#{topic}#{ext}"
    end
    
    def resolve_landing_page_or_default_topic(locale = nil)
      if (Settings[:LANDING_PAGE] && 'true'.eql?(Settings[:LANDING_PAGE]))
        begin
          @locale = set_locale(locale)
          @rows = get_rows_from_view(@db, "content_views/deliverable_meta", @locale)
          haml :landing_page
        rescue 
          haml :'404'
        end
      else
        redirect_to_default_topic(@locale, @version)
      end
    end
    
    #Redirect to the default topic page
    def redirect_to_default_topic(locale, version, deliverable = nil)
      locale = set_locale(locale)
      version = set_version(version)
#      puts "Redirecting to #{meta_doc['default_topic']}"
      #if a deliverable was specified, grab the default topic from the .meta documents
      if(not(deliverable.nil?))
        begin
          id = get_deliverable_metadata_id(locale, version, deliverable)
          meta_doc = get_document_by_id(@db, id)
          #make sure this is called last, otherwise it'll call for every topic
          call_topic(locale, version, meta_doc['default_topic']);
        rescue => e
          puts e.class
          puts e.message
          haml :'404'
        end
      else
        #go to default topic
        call_topic(locale, version, settings.default_topic);
      end
    end
    
    #Call the topic instead of redirecting
    def call_topic(locale, version, topic)
      #env.merge will not force a URL structure
      #status, headers, body = call! env.merge("PATH_INFO" => "/#{locale}/#{version}/#{topic}")
      #[status, headers, body]
      
      #Redirect rather than call in order to force a URL structure
      redirect to("/#{locale}/#{version}/#{topic}")
    end
  end
end
