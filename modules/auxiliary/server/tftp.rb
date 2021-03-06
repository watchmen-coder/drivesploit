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
require 'rex/proto/tftp'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::TFTPServer
	include Msf::Auxiliary::Report

	def initialize
		super(
			'Name'        => 'TFTP File Server',
			'Version'     => '$Revision$',
			'Description'    => %q{
				This module provides a TFTP service
			},
			'Author'      => [ 'jduck' ],
			'License'     => MSF_LICENSE,
			'Actions'     =>
				[
				 	[ 'Capture' ]
				],
			'PassiveActions' =>
				[
					'Capture'
				],
			'DefaultAction'  => 'Capture'
		)

		register_options(
			[
				OptString.new('TFTPROOT',   [ false,  "The TFTP root directory to serve files from" ]),
				OptString.new('OUTPUTPATH', [ false, "The directory in which uploaded files will be written." ])
			], self.class)
	end

	def run
		if not datastore['OUTPUTPATH'] and not datastore['TFTPROOT']
			print_error("You must set TFTPROOT and/or OUTPUTPATH to use this module.")
			return
		end

		@tftp = Rex::Proto::TFTP::Server.new

		print_status("Starting TFTP server...")

		if datastore['TFTPROOT']
			print_status("Files will be served from #{datastore['TFTPROOT']}")
			@tftp.set_tftproot(datastore['TFTPROOT'])
		end

		# register output directory
		if datastore['OUTPUTPATH']
			print_status("Uploaded files will be saved in #{datastore['OUTPUTPATH']}")
			@tftp.set_output_dir(datastore['OUTPUTPATH'])
		end

		# Individual virtual files can be served here -
		#@tftp.register_file("ays", "A" * 2048) # multiple of 512 on purpose

		@tftp.start

		# Wait for finish..
		@tftp.thread.join

		#print_status("Stopping TFTP server") if datastore['VERBOSE']
		#@tftp.stop
	end

end
