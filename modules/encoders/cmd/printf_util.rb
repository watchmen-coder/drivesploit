##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Encoder

	# Has some issues, but overall it's pretty good
	# - printf(1) may not be available
	# - requires: "\x7c\x73\x68\x5c\x78"
	# - doesn't work on windows
	# - min size increase: 4x + 9
	# - max size increase: 4x + 14
	Rank = GoodRanking

	def initialize
		super(
			'Name'             => 'Generic printf(1) Utility Command Encoder',
			'Version'          => '$Revision$',
			'Description'      => %q{
					This encoder uses the printf(1) utility to avoid restricted
				characters. Some shell variable substituion may also be used
				\if needed symbols are blacklisted.
			},
			'Author'           => 'jduck',
			'Arch'             => ARCH_CMD,
			'EncoderType'      => Msf::Encoder::Type::PrintfUtil)
	end


	#
	# Encodes the payload
	#
	def encode_block(state, buf)

		# Skip encoding for empty badchars
		if(state.badchars.length == 0)
			return buf
		end

		# If backslash is bad, we are screwed.
		if (state.badchars.include?("\\")) or
			(state.badchars.include?("|")) or
			# We must have at least ONE of these two..
			(state.badchars.include?("x") and state.badchars.include?("0"))
			raise RuntimeError
		end

		# Now we build a string of the original payload with bad characters
		# into \0<NNN> or \x<HH>
		if (state.badchars.include?('x'))
			hex = buf.unpack('C*').collect { |c| "\\0%o" % c }.join
		else
			hex = buf.unpack('C*').collect { |c| "\\x%x" % c }.join
		end

		# Build the final output
		ret = "printf"

		# Special case: <SPACE>, try to use ${IFS}
		if (state.badchars.include?(" "))
			ret << '${IFS}'
		else
			ret << " "
		end

		ret << hex << "|sh"

		return ret
	end

end
