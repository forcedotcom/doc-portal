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


require 'sinatra/base'
require_relative 'general_helpers.rb'

module Sinatra
  module CouchPortalHelpers
    include GeneralHelpers
    
    # Get the MIME type for an attachment/file/whatever, the set the
    # content_type for the route based on the extension passed in.
    # @param extension - The extension type of the file who's MIME
    # type we are trying to find.
    def set_content_type(extension)
      content_type Rack::Mime.mime_type(extension, "application/json")
    end
    
    #Get the Table of Content document
    def get_toc(db, locale, version, directory, ttl = settings.long_ttl)
      tocId = get_toc_id(locale, version, directory)
      return get_from_db_or_cache(db, tocId, {:trx => CouchDBTransaction::GET, :field => 'body_content'}, ttl)
    end

    # Returns the body_content field from a document
    # @param db [CouchRest::Database] The database to use.
    # @param id [String] the id of the document
    # @return [String] the body_content field of the document
    # @todo Add exception handling
    def get_html_body(db, locale, version, name, ttl=settings.long_ttl)
      id = get_topic_or_image_id(locale, version, name)
      return get_from_db_or_cache(db, id, {:trx => CouchDBTransaction::GET, :field => 'body_content'}, ttl)
    end
    
    def get_document_by_id(db, id, ttl = settings.long_ttl)
      return get_from_db_or_cache(db, id, {:trx => CouchDBTransaction::GET}, ttl)
    end
    
    # Get an entire document from the database
    # @param db [CouchRest::Database] The database to use.
    # @param id [String] the id of the document
    # @return [CouchRest::Document] a couchrest document
    def get_rows_from_view(db, view_name, key, ttl = settings.long_ttl)
      return get_from_db_or_cache(db, view_name, {:trx => CouchDBTransaction::VIEW, :view_name => view_name, :key => key}, ttl)
    end

    # Get the attachment from the cache, or push it into the cache
    # @param id [String] the id of the couchdb document
    # @param attachment_name [String] the name of the attachment to return
    # @param time_to_live [Fixnum] time before the cached item needs to be refetched 
    def get_attachment(db, locale, version, attachment_name, ttl=settings.long_ttl)
      id = get_topic_or_image_id(locale, version, attachment_name)
      return get_from_db_or_cache(db, id, {:trx => CouchDBTransaction::FETCH_ATTACHMENT, :attachment_name => attachment_name}, ttl)
    end

    # Return the correct locale for the helper
    def set_locale(locale)
      # Parse the HTTP GET header for languages and create an array
      # from them
      locales = ::R18n::I18n.parse_http(request.env['HTTP_ACCEPT_LANGUAGE'])

      # If we passed in a locale param, put it at the front of the
      # locales array
      if ((locale.is_a? String) && !(locale.empty?))
        locales.insert(0, locale)
      end

      # R18N locale setter
      ::R18n.thread_set do
        if Settings[:DEFAULT_LOCALE]
          ::R18n::I18n.default = Settings[:DEFAULT_LOCALE]
        end
        
        ::R18n::I18n.new(locales, ::R18n.default_places,
                         :off_filters => :untranslated, :on_filters => :untranslated_html)
      end
      
      begin
        # We depend on lang-locale, not just lang code.
        # If we get a 2 letter lang code, dupe it so that
        # de becomes de-de
        # unless it's en, then we want en-us
        # or ja then we want ja-jp
        if (locales[0].length == 2)
          case locales[0].downcase
          when "en"
            return "en-us"
          when "ja"
            return "ja-jp"
          else
            return "#{locales[0].downcase}-#{locales[0].downcase}"
          end
        else
          return locales[0].downcase
        end
      rescue
        return Settings[:DEFAULT_LOCALE]
      end
    end

    # Set the version of the page based on the value of the topic.  Fallback to the default if you can't set it.
    def set_version(version = nil)
      begin
        if (defined?(version) && not(version.nil? ))
        then
          return version
        else
          return Settings[:CURRENT_VERSION]
        end
      rescue
        return Settings[:CURRENT_VERSION]
      end
    end

    # Abstracting the search method.
    # Try to search using couchdb_lucene, if that fails, because the handler isn't found, use search_cloudant
    def search(db, locale, version, query, view = settings.view)
      return get_from_db_or_cache(db, nil, {:trx => CouchDBTransaction::SEARCH, :locale => locale, :version => version, :query => query, :view => view})
    end

  end
  helpers CouchPortalHelpers
end

