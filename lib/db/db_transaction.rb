=begin
 Encapsulates db interactions such as uploading files and creating search docs
=end
require 'bundler'
Bundler.require(:default, (ENV['RACK_ENV'] || :development).to_sym)
require 'base64'
require 'logging'
require_relative '../../helpers/construct_data_helpers.rb'
require_relative '../../helpers/general_helpers.rb'

class DB_Transaction 
  include ConstructDataHelpers
  include GeneralHelpers
  
  #Constructor to initialize the logger and db
  def initialize (logger, db)
    if logger.nil?
      @log = Logging.logger['db_upload']
      @log.add_appenders(
        Logging.appenders.stdout
      )
      @log.level = Logger::DEBUG
    else
      @log = logger
      @log.debug "Using in-memory logger"
    end
    
    if db.nil?
      raise "The database object has not been initialized. Please initialize it first"
    else
      @db = db
    end
    # Need to clear the cache after each upload
    begin
      dc = Dalli::Client.new
      dc.flush
    rescue => e
      puts "The memcached server is not available."
    end
    
    #global variable that contains information about the checksum/revisions of docs
    @id_checksum_hash = Hash.new
  end
  
  # Lookup the mime type using Rack
  # @param [String] extension the extension of the file, including the
  # period, `.css` or `.html`.
  # @return [String] the mime type.
  def get_mime_type(extension)
    begin
      return Rack::Mime.mime_type(extension)
    rescue
      @log.warn "Couldn't find the MIME type for #{extension}."
      return 'text/json'
    end
  end
  
  ##
  #Create a document representation from a JSON file
  #id - The id of the document to create
  #fq_filename - The fully qualified filename to parse and extract data from
  def create_doc_from_json(id, fq_filename)
    json_doc = JSON.parse(File.read(fq_filename))
    json_doc["_id"] = id
    json_doc[:content_hash] = generateCheckSum(json_doc.to_s)
    json_doc[:updated] = Time.now.to_date.iso8601
    json_doc[:version] = Settings[:CURRENT_VERSION]
    
    upsert_doc_via_checksum(@db, json_doc, [:version], @id_checksum_hash[id], @log)
    return json_doc
  end
  
  def create_plain_file(fq_filename, id, locale)
    @log.debug "Creating a document for #{fq_filename}"
    
    #get the array of json data
    content = File.read(fq_filename)
    
    #doc fields to create, if needed
    newDoc = {
      '_id' => id,
      :body_content => content,
      :content_hash => generateCheckSum(content),  #checksum on the file content that if the logic to construct the toc changes, we'll update it in the db
      :locale => locale,
      :updated => Time.now.to_date.iso8601,
      :version => Settings[:CURRENT_VERSION]}
    
    #upsert the document
    upsert_doc_via_checksum(@db, newDoc, [:locale, :version], @id_checksum_hash[id], @log)
  end 
  
  # Create a new document in couchdb.  If the document already exists, nothing
  # will happen and no error will be thrown.  
  # @param document_name [String] The name of the document to create.
  # @param locale [String] The lang-locale of this document
  # @param version [String] The version of this document.
  # @param deliverable_json [JSON] The json metadata representaition of the parent deliverable
  # @return [String] The response from the database
  def create_html_document(directory, filename, locale, deliverable_json = nil)
    version = Settings[:CURRENT_VERSION]
  
    # Why not let CouchDB create the ID?  Because it actually affects performance.
    # Also, if we define the ID, then we can find the document without a view.
    id = "#{Settings[:APP_NAME]}.#{filename}.#{locale}.#{version}"
    
    # Create a Nokogiri document from the XML file on disk
    content_doc = Nokogiri::XML(open("#{directory}/#{filename}")){|config| config.noent }
    content_doc.remove_namespaces!
  
    # Figure out the title for the document, pick it up from the
    # Dublin Core metadata, if available, otherwise grab it from the
    # title element.
    title=content_doc.xpath("/html/head/meta[@name = 'DC.Title']/@content")
    title ||= content_doc.xpath('/html/head/title').inner_text().to_s
    title = title.to_s rescue nil
    
    # Add facets.
    # The rescue nil is there because if something happens, we're okay
    # with no value.
    app_area = content_doc.xpath("/html/head/meta[@name = 'app_area']/@content").to_s rescue nil      
    role = content_doc.xpath("/html/head/meta[@name = 'role']/@content").to_s rescue nil
    edition = content_doc.xpath("/html/head/meta[@name = 'edition']/@content").to_s rescue nil
    topic_type = content_doc.xpath("/html/head/meta[@name = 'topic_type']/@content").to_s rescue nil
    technology = content_doc.xpath("/html/head/meta[@name = 'SFDC.Technology']/@content").to_s rescue nil

    # Add deliverable title and other metadata
    deliverable_title = deliverable_json['title'] rescue nil
    deliverable_type = deliverable_json['type'] rescue nil
    deliverable_pdf_name = content_doc.xpath("/html/head/meta[@name = 'SFDC.RelatedPDF']/@content").to_s rescue nil
    deliverable_pdf_url = content_doc.xpath("/html/head/meta[@name = 'SFDC.RelatedPDFURL']/@content").to_s rescue nil
    deliverable_home = deliverable_json['default_topic'] rescue nil
    
    #scrub the table of data we don't need
    body_content = content_doc.xpath('/html/body/*')
    scrub_table(body_content)
    body_content = body_content.to_html
    

    # Create a document to add the searchable text. We have to create a
    # new document, we can't reuse content_doc. That's because nodesets
    # are queries of documents. In other words, if you do a
    # nodeset.xpath('//xpath').remove, it removes that xpath from all
    # nodesets created from a document, not just nodeset.
    search_doc = content_doc.dup
  
    # Remove items we don't want returned in the search snippet
    search_content=search_doc.xpath('/html/body')
    search_content.xpath('/html/body//table[contains(@class, "permTable") or contains(@class, "editionTable")]').remove
    search_content.xpath('/html/body//*[contains(@class, "breadcrumb")]').remove
    search_content.xpath('/html/body/h1[1]').remove
    
    # Encode the search_content, replacing unsafe codepoints.  This allows search to find items like >
    coder = HTMLEntities.new
    search_content=coder.encode(search_content.children().inner_text()).strip
    
    #remove weird new line characters
    search_content = search_content.gsub("\n", ' ')
    search_content = HTMLEntities.new.decode(search_content)
    
    #doc fields to create, if needed
    newDoc = {
      '_id' => id,
      :name => filename,
      :locale => locale,
      :version => version,
      :title => title,
      :body_content => body_content,
      :app_area => app_area,
      :role => role,
      :edition => edition,
      :topic_type => topic_type,
      :technology => technology,
      :deliverable_title => deliverable_title,
      :deliverable_type => deliverable_type,
      :deliverable_pdf_name => deliverable_pdf_name,
      :deliverable_pdf_url =>  deliverable_pdf_url,
      :deliverable_home => deliverable_home,
      :search_content => search_content}
      
    #This content hash accounts for changes necessary from the deliverable metadata as well as changes to the xml document in general
    newDoc[:content_hash] =  generateCheckSum(newDoc.inspect)
    
    #Dynamic content added after the hash
    newDoc[:updated] = Time.now.to_date.iso8601
      
    #upsert the document
    upsert_doc_via_checksum(@db, newDoc, [:locale, :version], @id_checksum_hash[id], @log)
    
    return id
  end
  
  # Parse the HTML file and upload referenced images
  # @param directory [String] the directory the file is stored in
  # @param filename [String] the name of the file
  # @param locale [String] The lang-locale of this document
  # @param body_content [Nokogiri::NodeSet] the nodeset that represents the contents of the body
  # @return [String] The response from the database
  def upload_referenced_images(directory,filename,locale)
    version = Settings[:CURRENT_VERSION]
    begin
      doc_path = "#{directory}/#{filename}"
      relative_directory = File.dirname(doc_path) 
      content_doc = Nokogiri::XML(open(doc_path)){|config| config.noent }
      content_doc.remove_namespaces!
      # Find each img element
      content_doc.xpath('//img').each do |img|
        # Steps for uploading content
        # 1. Create a hash of the file
        # 2. Get a unique path.
        # 3. Get the filename of the referenced document for the
        # attachment name
        # 4. Check to see if that document exists, if it does, compare
        # the hashes and only upload if it has changed.

        # If the image starts with a / assume the file will be in the public directory
        unless (img['src'].start_with?('/'))
          mime_type = get_mime_type(img['src'][/(?:.*)(\..*$)/, 1])

          # Get the directory from the filename
          dir_match_re = /(.*)\//
          file_dir = dir_match_re.match(filename)[1]

          # Fix relative paths here
          path_from_source = (Pathname.new img['src'])
          image_path = (Pathname.new("#{file_dir}/#{img['src']}")).cleanpath.to_s
          id = "#{Settings[:APP_NAME]}.#{image_path}.#{locale}.#{version}"
          
          full_image_path = (Pathname.new("#{directory}/#{image_path}")).cleanpath.to_s

          # Get the hash of the file on the filesystem
          np = Digest::MD5.file(full_image_path)
          attachment_hash = "md5-#{Base64.encode64(np.digest)}".strip
          
          # Look at the attachments on the document in the database
          # If there is an existing attachment with the same name, check the hash value.
          # If it's the same, don't upload it.
          # If it's different, upload it.

          #doc fields to create, if needed
          newDoc = {
            '_id' => id,
            :name => image_path,
            :locale => locale,
            :version => version,
            :updated => Time.now.to_date.iso8601,
            :content_hash => attachment_hash }
      
          #doc fields to update, if needed
          updatedDoc = {
            :updated => Time.now.to_date.iso8601,
            :content_hash => attachment_hash }
    
          #upsert the document
          upsert_doc(@db, newDoc, updatedDoc, :content_hash, @log)
          
          doc = @db.get(id)
          doc_attachments = JSON.parse(doc.to_json)["_attachments"]

          # If there are no attachments, then doc_attachments will be Nil
          if (doc_attachments.is_a? Hash)
            # If there is already an attachment with the same name, check the hash.
            # If the hash is different, update it.
            unless (doc_attachments.has_key?(image_path) && doc_attachments[image_path]["digest"].eql?(attachment_hash))
              begin
                @db.put_attachment(doc, image_path, open(full_image_path, &:read), :content_type => mime_type)
              rescue RestClient::Conflict
                @log.warn "Hit a conflict.  Deleting the attachment and trying again."
                begin
                  @db.delete_attachment(doc,image_path,true)
                  begin
                    # Have to get the document again, since the _rev has changed
                    doc = @db.get(id)
                    @db.put_attachment(doc, image_path, open(full_image_path, &:read), :content_type => mime_type)
                  rescue => e
                    @log.error"The attachment was deleted, but could not be re-added."
                    @log.error e.class
                    @log.error e.message
                  end
                rescue => e
                  @log.warn "Something went wrong when deleting the attachment.  Unknown state."
                  @log.error e.class
                  @log.error e.message
                end
              rescue => e
                @log.error "Something went wrong when adding an attachment - #{img['src']} on #{doc_path}"
                @log.error e.message
                @log.error e.class
              end
            end
          else
            # There are no attachments on this document.  Add this one.
            @db.put_attachment(doc, image_path, open(full_image_path, &:read), :content_type => mime_type)
          end
        end
      end
    rescue => e
#      @log.error "Something went wrong when adding an attachment - #{img['src']} on #{doc_path}"
      @log.error e.message
      @log.error e.class
    end
  end
  
  # Change to Settings[:CONTENT_DIR]/locale and upload the files there
  # @todo Add uploads of dependent files (images, etc.)
  # @todo What about json, css, etc.?
  def upload_directory(locale, directory)
    @log.debug "Looking for files in #{directory}"
    Dir.chdir(directory)
    
    #Get all document ids by locale
    @id_checksum_hash = get_id_checksum_hash(locale)
    
    #Loop through every deliverable and upload its content
    Dir.glob("*") do | deliverable_dir |
      @log.debug "Descending into #{locale}/#{deliverable_dir}"
      
      #Upload the deliverable metadata
      deliverable_metadata = nil
      Dir.glob("#{deliverable_dir}/deliverable_metadata.json") do | metadata_file |
        @log.debug "Attempting to upload metadata for #{locale}/#{metadata_file}"
        id = get_deliverable_metadata_id(locale, Settings[:CURRENT_VERSION], deliverable_dir)
        deliverable_metadata = create_doc_from_json(id, metadata_file)
      end
      
      #Upload the toc file
      Dir.glob("#{deliverable_dir}/*.toc") do | toc_file |
        @log.debug "Attempting to upload ToC for #{locale}/#{toc_file}"
        id = get_toc_id(locale, Settings[:CURRENT_VERSION], deliverable_dir)
        create_plain_file(toc_file, id, locale)
      end
      
      #Upload the html files and their referenced dependencies
      Dir.glob ("#{deliverable_dir}/**/*.{html,htm}") do | html_file |
        @log.debug "Attempting to upload html for #{locale}/#{html_file}"
        create_html_document(directory, html_file, locale, deliverable_metadata)
        
        @log.debug "Attempting to upload dependencies for #{locale}/#{html_file}"
        upload_referenced_images(directory, html_file, locale)
      end
    end
  end
  
  ##
  # Scrub the tables of any information that is not required
  # Create every <td> with a data-title attribute
  def scrub_table(body_content)
    body_content.xpath('//table/@cellpadding').remove rescue nil
    body_content.xpath('//table/@cellspacing').remove rescue nil
    
    body_content.xpath('//table//th/@align').remove rescue nil
    body_content.xpath('//table//th/@valign').remove rescue nil
    body_content.xpath('//table//th/@width').remove rescue nil
    body_content.xpath('//table//th/@height').remove rescue nil
    
    body_content.xpath('//table//td/@align').remove rescue nil
    body_content.xpath('//table//td/@valign').remove rescue nil
    body_content.xpath('//table//td/@width').remove rescue nil
    body_content.xpath('//table//td/@height').remove rescue nil
  end
  
  ##
  # Returns a hash whose key is a document id and whose value is an array of checksum and revision
  # @param locale [String] The locale to filter results by
  def get_id_checksum_hash(locale)
    #Gather all ids to retrieve from the db
    ids = Array.new
    Dir.glob("*/*") do | file_name |
      if (file_name.end_with? "deliverable_metadata.json")
        ids.push(get_deliverable_metadata_id(locale, Settings[:CURRENT_VERSION], file_name.split("/")[0])) 
      elsif (file_name.end_with? ".toc")
        ids.push(get_toc_id(locale, Settings[:CURRENT_VERSION], file_name.split("/")[0]))
      elsif (file_name.end_with?(".htm", ".html"))
        ids.push(get_topic_or_image_id(locale, Settings[:CURRENT_VERSION], file_name))
      end
    end
    
    #get the id,hash results 
    rows = @db.view("content_views/checksum_by_id", :keys => ids)['rows']
    id_checksum_hash = Hash.new(rows.size)
    
    #store it in a hash
    rows.each { |result|
      id_checksum_hash[result["key"]] = result["value"]
    }
    return id_checksum_hash
  end
  
  # Add the search doc for couchdb-lucene
  def create_search_doc_couchdb_lucene(locales = [Settings[:DEFAULT_LOCALE]])
    json_doc = JSON.parse(File.read(Pathname.new(File.dirname(__FILE__) + "/../../" + "couchdb_views/lucene_search_view.json").cleanpath))
    json_doc["fulltext"]["by_content"]["index"] = construct_design_doc("couchdb_views/lucene_search_view.js", locales)
    json_doc[:content_hash] = generateCheckSum(json_doc["fulltext"]["by_content"]["index"])
    json_doc[:updated] = Time.now.to_date.iso8601
    upsert_doc(@db, json_doc, json_doc, :content_hash, @log)
  end

  # Add the search doc for cloudant search 2.0
  # The "special" index named default is the default and will match searches without a locale.
  def create_search_doc_cloudant(locales = [Settings[:DEFAULT_LOCALE]])
    json_doc = JSON.parse(File.read(Pathname.new(File.dirname(__FILE__) + "/../../" + "couchdb_views/cloudant_search_view.json").cleanpath))
    json_doc["indexes"]["by_content"]["analyzer"]["fields"] = "{#{locales2languages(locales)}}"
    json_doc["indexes"]["by_content"]["index"] = construct_design_doc("couchdb_views/cloudant_search_view.js", locales)
    json_doc[:content_hash] = generateCheckSum(json_doc["indexes"]["by_content"]["index"])
    json_doc[:updated] = Time.now.to_date.iso8601
    upsert_doc(@db, json_doc, json_doc, :content_hash, @log)
  end
  
  ##
  # Create design document for views
  def construct_view()
    design_docs = ["couchdb_views/content_views.json"]
    design_docs.each { |design_doc|
      #Read the file
      content = File.read(Pathname.new(File.dirname(__FILE__) + "/../../" + design_doc).cleanpath)
      check_sum = generateCheckSum(content)
      
      #create the JSON
      design_doc_as_json = JSON.parse(content)
      design_doc_as_json[:content_hash] = check_sum
      
      #upload the JSON as a design document
      upsert_doc(@db, design_doc_as_json, design_doc_as_json, :content_hash, @log)
    }
  end
  
  #Driver method that creates the search docs and uploads all files in the specified content directory
  def create_search_docs_and_upload(wd)
    started_at = Time.now
    
    #upload all files
    if wd.nil?
      wd = Dir.getwd
    end
    
    langs = Array.new
    if (Settings[:lang].nil?)
      @log.debug "Environment :lang variable not set. Uploading directory: #{wd}/#{Settings[:CONTENT_DIR]}"
      
      # Lang has not been set at the command-line, so do them all
      langs = []
      Pathname.glob("#{wd}/#{Settings[:CONTENT_DIR]}/*").map { |i|
        langs << i.basename 
      }
    else
      langs = Settings[:lang]
    end
    
    #we didn't find any languages. this might happen if the directory is empty or doesn't exist
    if (langs.empty?)
      langs = [Settings[:DEFAULT_LOCALE]]
    end
    
    #create the search docs for both lucene and cloudant
    create_search_doc_couchdb_lucene(langs)
    create_search_doc_cloudant(langs)
    construct_view()
    bulk_save()
    
    # Loop over the array of langs and upsert each directory
    langs.each {|i|
      begin
        locale_dir = "#{wd}/#{Settings[:CONTENT_DIR]}/#{i}"
        @log.debug "Attempting to upload directory in: #{locale_dir}"
        if File.directory? locale_dir
          #Upload this language and save it
          upload_directory(i, locale_dir)
          bulk_save()
        else
          @log.debug "#{locale_dir} does not exist.  Skipping."
        end
      rescue => e
        @log.error "Couldn't upload #{locale_dir}."
        @log.error e.class
        @log.error e.message
      end
    }
    @log.info "Upload duration: #{Time.now - started_at}"
  end
  
  #Bulk save
  def bulk_save() 
    begin
      @log.info "Bulk saving documents"
      @db.bulk_save
    rescue => e
      puts "Something went wrong in the bulk save"
      @log.error e.class
      @log.error e.message
    end
  end
end
