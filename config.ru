require File.dirname(__FILE__) + '/application.rb'
$stdout.sync = true
use Rack::Deflater
run SFDC::Portal
