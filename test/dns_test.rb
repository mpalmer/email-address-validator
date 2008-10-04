require File.dirname(__FILE__) + '/test_helper'

class DnsTest < Test::Unit::TestCase
	def setup
		EmailAddressValidator.reset!
	end
	
	def test_mx_success
		Resolv::DNS.expects(:new).returns(dns = mock)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns(['something'])
		
		EmailAddressValidator.check_dns = true
		assert EmailAddressValidator.validate('somebody@example.com')
	end

	def test_a_record_success
		Resolv::DNS.expects(:new).returns(dns = mock)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([])
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).returns(['something'])
		
		EmailAddressValidator.check_dns = true
		assert EmailAddressValidator.validate('somebody@example.com')
	end

	def test_failure
		Resolv::DNS.expects(:new).returns(dns = mock)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([])
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).returns([])
		
		EmailAddressValidator.check_dns = true
		assert !EmailAddressValidator.validate('somebody@example.com')
	end
end
		
