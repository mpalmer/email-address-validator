require File.dirname(__FILE__) + '/test_helper'

class DebugTest < Test::Unit::TestCase
	def setup
		EmailAddressValidator.reset!
	end
	
	def test_debug
		$stderr.expects(:puts).with('blargh')
		
		EmailAddressValidator.debug = true
		EmailAddressValidator.debug 'blargh'
	end
	
	def test_no_debug
		$stderr.expects(:puts).never
		
		EmailAddressValidator.debug = false
		EmailAddressValidator.debug 'blargh'
	end
end
