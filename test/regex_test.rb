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
	
	def test_more_interesting_addresses
		['"Abc\\@def"@example.com',
		 '"Fred Bloggs"@example.com',
		 '"Joe\\\\Blow"@example.com',
		 '"Abc@def"@example.com',
		 'customer/department=shipping@example.com',
		 '$A12345@example.com',
		 '!def!xyz%abc@example.com',
		 '_somename@example.com',
		 '"test\\\\blah"@example.com',
		 '"test\\blah"@example.com',
		 '"test\\\\\\rblah"@example.com',
		 '"test\\"blah"@example.com',
		 'customer/department@example.com',
		 '$A12345@example.com',
		 '!def!xyz%abc@example.com',
		 '_Yosemite.Sam@example.com',
		 '~@example.com',
		 '"Austin@Powers"@example.com',
		 'Ima.Fool@example.com',
		 '"Ima.Fool"@example.com',
		 '"Ima Fool"@example.com'
		].each do |addr|
			assert EmailAddressValidator.validate(addr)
		end
	end

	def test_invalid_addresses
		['NotAnEmail',
		 '@NotAnEmail',
		 '\\"test\\rblah\\"@example.com',
		 '"test"blah"@example.com',
		 '.wooly@example.com',
		 'wo..oly@example.com',
		 'pootietang.@example.com',
		 '.@example.com',
		 'Ima Fool@example.com'
		].each do |addr|
			assert !EmailAddressValidator.validate(addr)
		end
	end
end
