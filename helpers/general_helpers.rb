=begin
 General multi-purpose helpers 
=end
require 'logger'

class CouchDBTransaction
  module Type
    GET = 1 #Fetch an id
    FETCH_ATTACHMENT = 2  #Fetch attachment
    SEARCH = 3
    VIEW = 4
  end
  include Type
end 

module GeneralHelpers
  
  # Get the Table of Content id from the database given the following information:
  # locale - the locale of the toc
  # version - the version of the toc
  # directory - the directory of the toc
  def get_toc_id(locale, version, directory) 
    tocId = "#{Settings[:APP_NAME]}.#{locale}.#{version}."
    if(!(directory.nil?) && !(directory.empty?))
      tocId << "#{directory}."
    end
    tocId << "toc"
    return tocId
  end
  
  # Get the id for the topic or iamge
  # locale - the locale of the topic/image
  # version - the version of the topic/image
  # name - the name of the topic/image 
  def get_topic_or_image_id(locale, version, name)
    return "#{Settings[:APP_NAME]}.#{name}.#{locale}.#{version}"
  end
  
  def get_deliverable_metadata_id(locale, version, deliverable)
    return "#{Settings[:APP_NAME]}.#{locale}.#{version}.#{deliverable}.meta"
  end
  
  ##
  #Get data from the db or cache
  #db - the db to perform actions on
  #id - the id to return from the cache (may also be used when peforming a .get() on the db)
  #options - a hash of parameters to be passed into the appropriate method
  #ttl (optional) - the ttl to set for the cache
  def get_from_db_or_cache(db, id, options, ttl = settings.long_ttl)
    begin
      #if the cache isn't enabled, get data from the db
      if (!settings.enable_cache)
        return get_data_from_db(db, id, options, ttl)
      end
      
      #attachments and search have special keys to look for
      key = ""
      case options[:trx]
      when CouchDBTransaction::SEARCH
        key = "#{options[:locale]}/#{options[:version]}/#{options[:query]}"
      when CouchDBTransaction::VIEW
        key = "#{id}/#{options[:key]}"
      else
        key = id
      end
      
      # Trace how fast this happens
      self.class.trace_execution_scoped(["Custom/get_from_db_or_cache/check_for_nil_cache_#{key}"]) do
        cache_result = settings.cache.get(key)
        #if the cache is empty, get from the db
        if (cache_result.nil? || cache_result.empty?)
          document = get_data_from_db(db, id, options, ttl)
          # It would help performance if we didn't have to wait for this to return
          settings.cache.set(key, document, ttl)
          return document
        else
          # Get it from the cache
          return cache_result          
        end
      end

    rescue Dalli::RingError => e
      log_message(:error, "The memcache server is not available, trying the db")
      return get_data_from_db(db, id, options, ttl)
    end
  end
  
  ##
  #Get data from the db not the cache
  #db - the db to perform actions on
  #id - the id to return from the cache (may also be used when peforming a .get() on the db)
  #options - a hash of parameters to be passed into the appropriate method
  #ttl (optional) - the ttl to set for the cache
  def get_data_from_db(db, id, options, ttl = settings.long_ttl)
    begin
      case options[:trx]
      when CouchDBTransaction::FETCH_ATTACHMENT
        doc = db.get(id)
        return db.fetch_attachment(doc, options[:attachment_name])
      when CouchDBTransaction::SEARCH
        # Can't use " to set off this string, since it may contain quotes
        q = %Q[#{options[:locale]}_content:(#{options[:query]}) AND version:'#{options[:version]}']
        search_uri = "#{Settings[:db]}/#{options[:view]}"
        # Can't use CouchRest.view.  It hits a 400 error.
        response = RestClient.get search_uri, {:params => {:q => q, :limit => Settings[:MAX_SEARCH_RESULTS]}}
        return response.to_str
      when CouchDBTransaction::VIEW
        #Always allow stale views
        #http://wiki.apache.org/couchdb/HTTP_view_API#Querying_Options
        return db.view(options[:view_name], :key => options[:key], :stale => "ok")['rows']
      else
        doc = db.get(id)
        if (options[:field].nil?)
          return doc
        else
          return doc[options[:field]]
        end
      end
    end
  end
  
  ##
  # Inserts or updates a document in the database based on whether the checksum has changed
  # @param db [CouchRest::Database] The database to perform the action on
  # @param newDoc [Hash] The document to use when inserting
  # @param updateDoc [Hash] The document to use when updating an existing doc
  # @param checksumField [Symbol] The field that contains the checksum information
  # @param log [Logging] The log to update wtih messages regarding this transaction
  def upsert_doc(db, newDoc, updateDoc, checkSumField, log = nil)
    begin
      doc = db.get(newDoc['_id'])
      unless (doc[checkSumField].eql?(updateDoc[checkSumField]))
        #update all relevant fields specified
        updateDoc.each do |k, v|
          doc[k] = v
        end  
        
        #update the document
        log_message(:info, "Updating document with id #{doc['_id']}", log)
        db.save_doc(doc, true)
      end
    rescue RestClient::ResourceNotFound => e
      #doc not found, create it
      log_message(:info, "Creating a new document with id #{newDoc['_id']}", log)
      db.save_doc(CouchRest::Document.new(newDoc))
    rescue => e
      log_message(:error, "Cannot upsert document due to: ", log)
      log_message(:error, e.class.to_s, log)
      log_message(:error, e.message, log)
    end
  end
  
  ##
  # Inserts or updates a document in the database based on whether the checksum has changed
  # @param db [CouchRest::Database] The database to perform the action on
  # @param doc [Hash] The document to insert or update
  # @param ignorable_fields [Array] An array of symbols detailing which fields should NOT be updated
  # @param log [Logging] The log to update wtih messages regarding this transaction
  def upsert_doc_via_checksum(db, doc, ignorable_fields, old_checksum, log = nil)
    begin
      #we couldn't find this field in the database, update as new
      if ((old_checksum.is_a? Fixnum) || (old_checksum.nil?))
          #doc not found, create it
          log_message(:info, "Creating a new document with id #{doc['_id']}", log)
          db.save_doc(CouchRest::Document.new(doc))
      #Doc was found, nothing to update
      elsif (doc[:content_hash].eql? old_checksum)
        #log_message(:debug, "The document with id (#{doc['_id']}) has not changed. Nothing to update")
      #Document was found, content has changed, update it
      else
        #get the document from the database so we can preserve fields we're not touching *_*
        doc_to_update = db.get(doc['_id'])
        
        #Update all fields unless otherwise specified
        doc.each { |k, v|
          #if this is not a field to ignore updating, then update it!
          unless (ignorable_fields.include? k)
            doc_to_update[k] = v
          end
        }
        
        #Update the document
        log_message(:info, "Updating document with id #{doc['_id']}", log)
        db.save_doc(CouchRest::Document.new(doc_to_update))
      end
    rescue => e
      log_message(:error, "Cannot upsert document due to: ", log)
      log_message(:error, e.class.to_s, log)
      log_message(:error, e.message, log)  
    end
  end
  
  ##
  #Generate a check sum for use when checking to see if content has changed
  #content - The data to generate a checksum for
  def generateCheckSum(content)
    return Base64.encode64(Digest::MD5.digest(content)).strip
  end
  
  ##
  #Log a message to logger object OR the standard output
  #level - The warning level of the message (must be a 'Logger' type level)
  #message - The message to output
  #log - The logger object to output to (if nil or undefined then use std error/output)
  def log_message(level, message, log = nil)
    if (log.nil?)
      case level
      when :error
        STDERR.puts message
      else
        STDOUT.puts message
      end
    else
      case level
      when :fatal
        log.fatal message
      when :debug
        log.debug message
      when :warn
        log.warn message
      when :error
        log.error message
      else
        log.info message
      end
    end
  end
end
