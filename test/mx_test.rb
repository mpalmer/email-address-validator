require File.dirname(__FILE__) + '/test_helper'

class MxTest < Test::Unit::TestCase
	def test_failed_prerequisites
		EmailAddressValidator.check_mx = true
		assert_raise(RuntimeError) { EmailAddressValidator.validate('nobody@example.com') }
		EmailAddressValidator.from_address = 'example.com'
		assert_raise(RuntimeError) { EmailAddressValidator.validate('nobody@example.com') }
	end
	
	def test_successful_validate_on_mx
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.from_address = 'postmaster@example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('postmaster@example.org')
		smtp.expects(:rcptto).with('nobody@example.com')
		smtp.expects(:quit)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_failed_validate_on_mx
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.from_address = 'postmaster@example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('postmaster@example.org')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Net::SMTPFatalError.new)
		
		assert !EmailAddressValidator.validate('nobody@example.com')
	end

	def test_successful_validate_on_a_record
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.from_address = 'postmaster@example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([]).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).returns([rr = mock]).times(2)
		rr.expects(:address).returns('10.20.30.40')
		
		Net::SMTP.expects(:start).with('10.20.30.40', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('postmaster@example.org')
		smtp.expects(:rcptto).with('nobody@example.com')
		smtp.expects(:quit)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_failed_validate_on_a_record
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.from_address = 'postmaster@example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([]).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).returns([rr = mock]).times(2)
		rr.expects(:address).returns('10.20.30.40')
		
		Net::SMTP.expects(:start).with('10.20.30.40', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('postmaster@example.org')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Net::SMTPFatalError.new)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_fallthrough_validate
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.from_address = 'postmaster@example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('postmaster@example.org')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Net::SMTPServerBusy.new)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_timeout_validate
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.from_address = 'postmaster@example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('postmaster@example.org')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Timeout::Error.new)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

end
		
