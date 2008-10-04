require 'resolv'
require 'timeout'
require 'net/smtp'

class EmailAddressValidator
	class << self
		attr_accessor :check_dns, :check_mx, :from_address, :timeout
	end
	
	def self.validate(address)
		ok = true
		ok = validate_with_regex(address)
		return false unless ok
		ok = check_dns || check_mx ? validate_with_dns(address) : true
		return false unless ok
		ok = check_mx ? validate_with_mx(address) : true
		return ok
	end

	def self.debug=(v)
		@debug = v
	end
	
	def self.debug?
		@debug
	end

	def self.debug(*args)
		if debug?
			$stderr.puts args.map { |a| a.to_s }.join(' ')
		end
	end

	def self.validate_with_regex(address)
		EmailAddressValidator::Regexp::ADDR_SPEC =~ address
	end
	
	def self.validate_with_dns(address)
		EmailAddressValidator::Regexp::ADDR_SPEC =~ address
		domain = $2
		dns = Resolv::DNS.new
		return true if dns.getresources(domain, Resolv::DNS::Resource::IN::MX).length > 0
		return true if dns.getresources(domain, Resolv::DNS::Resource::IN::A).length > 0
		false
	end

	def self.validate_with_mx(address)
		EmailAddressValidator::Regexp::ADDR_SPEC =~ address
		domain = $2

		raise RuntimeError.new("Requested to check through MX, but no from address specified") if from_address.nil?
		raise RuntimeError.new("Malformed from address") unless EmailAddressValidator::Regexp::ADDR_SPEC =~ from_address
		helo_domain = $2

		dns = Resolv::DNS.new
		mxen = dns.getresources(domain, Resolv::DNS::Resource::IN::MX).sort_by { |rr| rr.preference }.map { |rr| rr.exchange.to_s }
		mxen.each do |mx|
			rv = check_through_mx(address, mx, helo_domain)
			return true if rv == :accept
			return false if rv == :fatal
		end
		
		if mxen.length == 0
			a_rec = dns.getresources(domain, Resolv::DNS::Resource::IN::A).map { |rr| rr.address.to_s }
			a_rec.each do |rr|
				rv = check_through_mx(address, rr, helo_domain)
				return true if rv == :accept
				return false if rv == :fatal
			end
		end

		# We fail "safe" by assuming that if we have MXes defined (previous
		# check) but can't talk to any of them that it's a transient error and
		# hence that the address is OK.
		true
	end

	def self.check_through_mx(address, mx, helo_domain)
		debug "Checking #{address} with #{mx}, from address is #{from_address} and hence helo is #{helo_domain}"
		
		begin
			Timeout.timeout(timeout || 1) do
				Net::SMTP.start(mx, 25, helo_domain) do |smtp|
					smtp.mailfrom(from_address)
					smtp.rcptto(address)
					smtp.quit
				end
			end
		rescue Net::SMTPFatalError
			debug "Fatal error; presumably the MX didn't like us"
			return :fatal
		rescue Timeout::Error
			debug "Timed out"
			return :timeout
		rescue StandardError => e
			debug "Error! #{e.class}: #{e.message}"
			return :unknown
		end
		
		debug "Fell out the bottom, so no problems"
		return :accept
	end
end
