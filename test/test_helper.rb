BASE_DIR = File.dirname(File.dirname(File.expand_path(__FILE__)))

$LOAD_PATH.unshift File.join(BASE_DIR, 'lib')

require 'email_address_validator'
require 'test/unit'
require 'rubygems'
require 'mocha'

class EmailAddressValidator
	def self.reset!
		@check_mx = @check_dns = @debug = false
		@helo_domain = nil
	end
end
