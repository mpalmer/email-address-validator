require 'resolv'
require 'timeout'
require 'net/smtp'

# Validate e-mail address format, MX availability, and whether the domain's
# mail server will accept mail for the user.
#
# = Overview =
#
# Like any data, an e-mail address that you accept from a user cannot just
# be accepted at face value, it needs to be validated.  It's non-trivial to
# do this, though -- not only do you have to make sure that it is formatted
# correctly (and this is harder than it first appears, as the rules for what
# constitute a valid e-mail address aren't simple), you also have to make
# sure that the e-mail address will actually receive mail.
#
# The EmailAddressValidator class tries, as much as possible without actually
# delivering an e-mail, to validate that an e-mail address is valid and will
# accept e-mail.  It does this in three stages:
#
# - Ensure that the e-mail address is correctly formatted, using a regular
#   expression derived from the ABNF specified in RFC2822 for maximum
#   correctness.  This takes very little resources.
#
# - Lookup MX records or A records for the domain part of the e-mail
#   address, to make sure that there's someone who might be willing to
#   receive mail.  This lookup requires network access and take a little bit
#   of time, but can catch a lot of simple typos.
#
# - Make an attempt to deliver an e-mail to the address, stopping just
#   before sending the message body.  This is the most accurate way to
#   discover whether an e-mail will be delivered, although it is still not
#   100% accurate (for example, Exchange servers will accept all mail at
#   SMTP time and then generate a bounce, so an SMTP-time test won't tell
#   you anything useful there).  However, most e-mail services will do the
#   right thing, and it is the only way to detect a typo'd local part.  It
#   does take a little while to perform this lookup, though.
#
# You can choose to enable different "levels" of validation in your app,
# depending on your performance requirements.  Regex validation is always
# turned on, and if you turn on delivery attempts the MX lookup will happen
# as well automatically.
#
# = Usage Examples =
#
# The only method you should really need to call to make things work is
# +::validate+. This method takes an e-mail address as it's sole argument,
# and returns true or false based on whether the address is valid or not.
#
# If you just want regex validation, all you need to do is call +::validate+:
#
#   EmailAddressValidation.validate('me@example.com')
#
# This will return either true or false depending on whether the address
# matches the regular expression.  To turn on DNS lookups, you need to set
# the +check_dns+ flag on the class:
#
#   EmailAddressValidation.check_dns = true
#
# Then calling +::validate+ will do MX/A record lookups on the domain, as
# well as the regex check.  To enable full delivery attempt checks, turn on
# +check_mx+ and, optionally, provide an FQDN to use in the HELO.  We'll try
# to guess an appropriate value if none is given, but it's quite common for
# the hostname of a machine to not be resolvable, which can give incorrect
# results.  You *must* ensure that there is a valid HELO domain, one way or
# another, if you want to expect good results.
#
#   EmailAddressValidation.check_mx = true
#   EmailAddressValidation.helo_domain = 'example.org'
#
# Since a delivery attempt can take a long time in certain pathological
# cases, we have a timeout set for each attempt to deliver to an MX.  By
# default, the timeout is set to 5 seconds (a nice median value), but you
# can change it to either be longer (which will reduce false negatives) or
# shorter, if you need better responsiveness (at the expense of more false
# negatives):
#
#   EmailAddressValidation.timeout = 10
#
# The value is in seconds, and it applies to each MX that is looked up -- so
# a domain with a large number of MXes can still take quite a while to
# complete a lookup.  If you have a need to limit the total time taken for a
# validation, you should wrap the validate call in your own timeout block.
#
# = Logging =
#
# If you want to see what's going on inside the class, you need to create a
# routine that accepts a single argument and do whatever you want with that
# string (the log message).  For example, if you want to print all debug
# messages to standard out, you can do it like this:
#
#   EmailAddressValidation.debug { |l| $stderr.puts l }
#
# At the moment, we've only got +debug+ level logging, but the plan is to get
# more levels sorted out shortly, so you can see why validations succeed or
# fail, for instance.
#

class EmailAddressValidator
	class << self
		attr_accessor :check_dns, :check_mx, :helo_domain, :timeout
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

	def self.debug(*args, &blk)
		if block_given?
			@debug = blk
		elsif !args[0]
			@debug = nil
		elsif @debug
			@debug.call(args.map { |a| a.to_s }.join(' '))
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

		dns = Resolv::DNS.new
		mxen = dns.getresources(domain, Resolv::DNS::Resource::IN::MX).sort_by { |rr| rr.preference }.map { |rr| rr.exchange.to_s }
		mxen.each do |mx|
			rv = check_through_mx(address, mx)
			return true if rv == :accept
			return false if rv == :fatal
		end
		
		if mxen.length == 0
			a_rec = dns.getresources(domain, Resolv::DNS::Resource::IN::A).map { |rr| rr.address.to_s }
			a_rec.each do |rr|
				rv = check_through_mx(address, rr)
				return true if rv == :accept
				return false if rv == :fatal
			end
		end

		# We fail "safe" by assuming that if we have MXes defined (previous
		# check) but can't talk to any of them that it's a transient error and
		# hence that the address is OK.
		true
	end

	def self.check_through_mx(address, mx)
		debug "Checking #{address} with #{mx}"
		
		helo = if helo_domain
			helo_domain
		else
			begin
				TCPSocket.gethostbyname(Socket.gethostname)[0]
			rescue SocketError
				raise RuntimeError.new "Failed to 'guess' at a HELO name; please provide one"
			end
		end
		
		begin
			Timeout.timeout(timeout || 5) do
				Net::SMTP.start(mx, 25, helo) do |smtp|
					smtp.mailfrom('')
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
