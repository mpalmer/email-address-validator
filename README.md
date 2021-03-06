# Email Address Validator

Like any data, an e-mail address that you accept from a user cannot just
be accepted at face value, it needs to be validated.  It's non-trivial to
do this, though -- not only do you have to make sure that it is formatted
correctly (and this is harder than it first appears, as the rules for what
constitute a valid e-mail address aren't simple), you also have to make
sure that the e-mail address will actually receive mail.

The EmailAddressValidator class tries, as much as possible without actually
delivering an e-mail, to validate that an e-mail address is valid and will
accept e-mail.  It does this in three stages:

* Ensure that the e-mail address is correctly formatted, using a regular
  expression derived from the ABNF specified in RFC2822 for maximum
  correctness.  This takes very little resources.

* Lookup MX records or A records for the domain part of the e-mail
  address, to make sure that there's someone who might be willing to
  receive mail.  This lookup requires network access and take a little bit
  of time, but can catch a lot of simple typos.

* Make an attempt to deliver an e-mail to the address, stopping just
  before sending the message body.  This is the most accurate way to
  discover whether an e-mail will be delivered, although it is still not
  100% accurate (for example, Exchange servers will accept all mail at
  SMTP time and then generate a bounce, so an SMTP-time test won't tell
  you anything useful there).  However, most e-mail services will do the
  right thing, and it is the only way to detect a typo'd local part.  It
  does take a little while to perform this lookup, though.

See the rdoc/ri documentation for full information on how to use this class,
or just look in `lib/email_address_validator/email_address_validator.rb`.
