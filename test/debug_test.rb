require File.dirname(__FILE__) + '/test_helper'

class DebugTest < Test::Unit::TestCase
	def setup
		EmailAddressValidator.reset!
	end
	
	def test_debug
		EmailAddressValidator.debug { |l| $stderr.puts l }
		$stderr.expects(:puts).with('blargh')
		
		EmailAddressValidator.debug 'blargh'
	end
	
	def test_turn_off_debug
		line = ''
		EmailAddressValidator.debug { |l| line = l }
		EmailAddressValidator.debug "foo"
		assert_equal 'foo', line
		
		EmailAddressValidator.debug false
		EmailAddressValidator.debug "bar"
		assert_equal 'foo', line
	end

	def test_no_debug
		$stderr.expects(:puts).never
		
		EmailAddressValidator.debug 'blargh'
	end
end
