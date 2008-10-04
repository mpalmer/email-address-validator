require File.dirname(__FILE__) + '/test_helper'

class RegexTest < Test::Unit::TestCase
	def setup
		EmailAddressValidator.reset!
	end
	
	def test_basic_addresses
		assert EmailAddressValidator.validate('nobody@example.com')
		assert EmailAddressValidator.validate('nobody+something@example.com')
		assert !EmailAddressValidator.validate('nobodyexample.com')
	end
end
		
