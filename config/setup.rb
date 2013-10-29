##
# Set the database
def set_db
  if (Settings[:db] && Settings[:APP_NAME])
    puts "CouchDB Server: #{Settings[:db]}"
    @server = CouchRest.new(server = Settings[:db])
  else
    puts "No database info defined.  Please set the environment variable CLOUDANT_URL."
    exit
  end
  
  # Check to see if the database exists. If it does, assume it's
  # correctly initialized. If not, create it.
  # I know when I looked at this I thought "define_available_database" would return a true or false,
  # but, by default, if the database doesn't exist, define_available_database will create it.
  begin
    @server.define_available_database(:default, Settings[:APP_NAME])
  rescue Exception => e
    puts "Couldn't use or create the database (#{Settings[:db]}/#{Settings[:APP_NAME]})."
    puts "Check to make sure that CLOUDANT_URL is correct."
    puts e
  end
  db = CouchRest.database("#{Settings[:db]}/#{Settings[:APP_NAME]}")
  return db
end

# We supprt three different search methods, in preference order
# 1. Cloudant search 2.0
# 2. couchdb-lucene proxy
# 3. couchdb-lucene python hooks
# Define which one to use by querying the database
def set_view
  #Are we a cloudant database?
  if (Settings[:db].include? "cloudant.com")
    return "#{Settings[:APP_NAME]}/_design/search/_search/by_content"
  else
    #Assuming a couchdb-lucene database
    begin
      if RestClient.get "#{Settings[:db]}/_fti/local"
          return "_fti/local/#{Settings[:APP_NAME]}/_design/lucene_search/by_content"
      end
    rescue => e
      begin
        if RestClient.get "#{Settings[:db]}/#{Settings[:APP_NAME]}/_fti/_design/lucene_search/by_content"
            return "#{Settings[:APP_NAME]}/_fti/_design/lucene_search/by_content"
          end
      rescue => e2
      end
    end
    #puts "Unable to find a search design doc. This may happen when the database is empty. Starting the app with a default search view "
    return "#{Settings[:APP_NAME]}/_fti/_design/lucene_search/by_content"
  end
end

#Load a property file and add it to the configliere Settings array
#fileName - The filename of the property file
def load_config_file(file_name)
  if (File.file?(file_name))
    prop_file = File.open(file_name)
    #go through each line and add it to the Settings array
    prop_file.readlines.each do |line|
      line.strip!
        
      #if it's not a comment 
      if (line[0] != ?# and line[0] != ?=)
        i = line.index('=')
        if (i)
          Settings[line[0..i - 1].strip] = line[i + 1..-1].strip
        else
          Settings[line] = ''
        end
      end
    end
    prop_file.close
  end
end

################################################################################

Settings.use :env_var, :commandline

#Environment variables

# Read the other config settings
Settings.read('config/app_config.yaml')
load_config_file(".env")  #This overrides the configs in the above files
Settings({
  #take the config from the environment if it's set, OR from a .env file if it's not set
  :db => ENV['CLOUDANT_URL'].nil? ? Settings[:CLOUDANT_URL] : ENV['CLOUDANT_URL'],
  :DEFAULT_TOPIC => ENV['DEFAULT_TOPIC'].nil? ? Settings[:DEFAULT_TOPIC] : ENV['DEFAULT_TOPIC'],
  :CURRENT_VERSION => ENV['CURRENT_VERSION'].nil? ? Settings[:CURRENT_VERSION] : ENV['CURRENT_VERSION'],
  :LANDING_PAGE => ENV['LANDING_PAGE'].nil? ? Settings[:LANDING_PAGE] : ENV['LANDING_PAGE'],
  :APP_TYPE => ENV['APP_TYPE'].nil? ? Settings[:APP_TYPE] : ENV['APP_TYPE'],
  :BETA => ENV['BETA'].nil? ? Settings[:BETA] : ENV['BETA'],
  :LOGIN_USERNAME => ENV['LOGIN_USERNAME'].nil? ? Settings[:LOGIN_USERNAME] : ENV['LOGIN_USERNAME'],
  :LOGIN_PASSWORD => ENV['LOGIN_PASSWORD'].nil? ? Settings[:LOGIN_PASSWORD] : ENV['LOGIN_PASSWORD']
})
Settings.resolve!

# Setup the database
if (Settings[:db] && Settings[:APP_NAME])
  puts "CouchDB Server: #{Settings[:db]}"
  @server = CouchRest.new(server = Settings[:db])
else
  puts "No database info defined.  Please set the environment variable CLOUDANT_URL."
  exit
end



