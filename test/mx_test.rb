require File.dirname(__FILE__) + '/test_helper'

class MxTest < Test::Unit::TestCase
	def setup
		EmailAddressValidator.reset!
	end
	
	def test_successful_validate_on_mx
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.helo_domain = 'example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com')
		smtp.expects(:quit)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_failed_validate_on_mx
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.helo_domain = 'example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Net::SMTPFatalError.new)
		
		assert !EmailAddressValidator.validate('nobody@example.com')
	end

	def test_successful_validate_on_a_record
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.helo_domain = 'example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([]).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).returns([rr = mock]).times(2)
		rr.expects(:address).returns('10.20.30.40')
		
		Net::SMTP.expects(:start).with('10.20.30.40', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com')
		smtp.expects(:quit)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_failed_validate_on_a_record
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.helo_domain = 'example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([]).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::A).returns([rr = mock]).times(2)
		rr.expects(:address).returns('10.20.30.40')
		
		Net::SMTP.expects(:start).with('10.20.30.40', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Net::SMTPFatalError.new)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_fallthrough_validate
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.helo_domain = 'example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Net::SMTPServerBusy.new)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_timeout_validate
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true
		EmailAddressValidator.helo_domain = 'example.org'
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'example.org').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com').raises(Timeout::Error.new)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

	def test_helo_domain_guessing
		EmailAddressValidator.check_dns = true
		EmailAddressValidator.check_mx = true

		Socket.expects(:gethostname).returns('faff')
		TCPSocket.expects(:gethostbyname).with('faff').returns(['faff.example.net'])
		
		Resolv::DNS.expects(:new).returns(dns = mock).times(2)
		dns.expects(:getresources).with('example.com', Resolv::DNS::Resource::IN::MX).returns([mx = mock]).times(2)
		mx.expects(:preference).returns(10)
		mx.expects(:exchange).returns('mx1.example.com')
		
		Net::SMTP.expects(:start).with('mx1.example.com', 25, 'faff.example.net').yields(smtp = mock)
		smtp.expects(:mailfrom).with('')
		smtp.expects(:rcptto).with('nobody@example.com')
		smtp.expects(:quit)
		
		EmailAddressValidator.validate('nobody@example.com')
	end

end
		
