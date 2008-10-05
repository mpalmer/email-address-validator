# regexp.rb -- regular expression elements to validate RFC2822 e-mail addresses
# Copyright (C) 2008 Matt Palmer <mpalmer@hezmatt.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

module EmailAddressValidator::Regexp
	ATEXT = /[A-Za-z0-9!#\$%&'\*\+\-\/=\?\^_`\{\|\}\~]/
	DOT_ATOM = /(?:#{ATEXT})+(?:\.(?:#{ATEXT})+)*/

	TEXT = /[\x01-\x09\x0B\x0C\x0E-\x7F]/
	QTEXT = /[\x01-\x08\x0B\x0C\x0E-\x1F\x21\x23-\x5B\x5D-\x7E]/
	QUOTED_PAIR = /\\#{TEXT}/
	QCONTENT = /(?:#{QTEXT}|#{QUOTED_PAIR})/
	QUOTED_STRING = /"(?:\s*#{QCONTENT})*\s*"/

	DTEXT = /[\x01-\x08\x0B\x0C\x0E-\x1F\x21-\x5A\x5E-\x7E]/
	DCONTENT = /(?:#{DTEXT}|#{QUOTED_PAIR})/
	DOMAIN_LITERAL = /\[(?:\s*#{DCONTENT})*\s*\]/
	DOMAIN = /(?:#{DOT_ATOM}|#{DOMAIN_LITERAL})/

	LOCAL_PART = /(?:#{DOT_ATOM}|#{QUOTED_STRING})/

	ADDR_SPEC = /^(#{LOCAL_PART})@(#{DOMAIN})$/
end
