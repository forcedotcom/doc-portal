$LOAD_PATH << './lib'
require 'db/db_transaction.rb'
require_relative 'config/setup.rb'

@db = set_db

log_name = "./log/upload_log_#{Time.now.strftime('%d-%m-%Y_%H%M%S')}.txt"
log = Logging.logger['db_upload']
log.add_appenders(
  Logging.appenders.stdout,
  Logging.appenders.file(log_name)
)
log.info "Logging the upload to #{log_name}"
log.level = Logger::INFO
log.info "Database info: #{@db.info}"

# Allow a command-line option to specify one or more languages to upload.
Settings.define :lang, :type => Array, :description => 'Specify the languages to upload to the database.'
Settings.resolve!

dbTransaction = DB_Transaction.new(log, @db)
dbTransaction.create_search_docs_and_upload(nil)

## Flush the remote cache
# Allow environment variables to override the .env file
begin
  if (not(ENV['MEMCACHIER_SERVERS'].nil?))
    remote_cache = Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
                              {:username => ENV["MEMCACHIER_USERNAME"],
                                :password => ENV["MEMCACHIER_PASSWORD"]})
  elsif (not(Settings[:MEMCACHIER_SERVERS].nil?))
    remote_cache = Dalli::Client.new(Settings[:MEMCACHIER_SERVERS].split(","),
                              {:username => Settings["MEMCACHIER_USERNAME"],
                                :password => Settings["MEMCACHIER_PASSWORD"]})
  end
  
  if(not(remote_cache.nil?))
    log.info "Flushing the remote cache"
    remote_cache.flush();
  end
rescue => e
  log.info "Error flushing the remote cache"
  log.info e.class
  log.info e.message
end

# Clear the localcache, too
begin
  local_cache = Dalli::Client.new('localhost:11211')
  
  if(not(local_cache.nil?))
    log.info "Flushing the local cache"
    local_cache.flush();
  end
rescue => e
  log.info "Error flushing the local cache"
  log.info e.class
  log.info e.message
end

log.info "Logged the upload to #{log_name}"
