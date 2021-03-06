
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


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::DCERPC
	include Msf::Exploit::Remote::SMB
	include Msf::Auxiliary::Scanner
	include Msf::Auxiliary::Report
	include Msf::Auxiliary::AuthBrute

	def proto
		'smb'
	end

	def initialize
		super(
			'Name'        => 'SMB Login Check Scanner',
			#'Version'     => '$Revision$',
			'Description' => %q{
				This module will test a SMB login on a range of machines and
				report successful logins.  If you have loaded a database plugin
				and connected to a database this module will record successful
				logins and hosts so you can track your access.
			},
			'Author'      => 'tebo <tebo [at] attackresearch [dot] com>',
			'License'     => MSF_LICENSE
		)
		deregister_options('RHOST','USERNAME','PASSWORD')

		# These are normally advanced options, but for this module they have a
		# more active role, so make them regular options.
		register_options(
			[
				OptString.new('SMBPass', [ false, "SMB Password" ]),
				OptString.new('SMBUser', [ false, "SMB Username" ]),
				OptString.new('SMBDomain', [ false, "SMB Domain", 'WORKGROUP']),
			], self.class)

	end

	def run_host(ip)
		vprint_status("Starting SMB login attempt on #{ip}")

		if accepts_bogus_logins?
			print_error("This system accepts authentication with any credentials, brute force is ineffective.")
			return
		end

		begin
			each_user_pass do |user, pass|
				try_user_pass(user, pass)
			end
		rescue ::Rex::ConnectionError
			nil
		end

	end

	def accepts_bogus_logins?
		orig_user,orig_pass = datastore['SMBUser'],datastore['SMBPass']
		datastore["SMBUser"] = Rex::Text.rand_text_alpha(8)
		datastore["SMBPass"] = Rex::Text.rand_text_alpha(8)

		# Connection problems are dealt with at a higher level
		connect()

		begin
			smb_login()
		rescue ::Rex::Proto::SMB::Exceptions::LoginError => e
		end

		disconnect
		datastore['SMBUser'],datastore['SMBPass'] = orig_user,orig_pass

		simple.client.auth_user ? true : false
	end

	def try_user_pass(user, pass)
		# The SMB mixins require the datastores "SMBUser" and
		# "SMBPass" to be populated.
		datastore["SMBUser"] = user
		datastore["SMBPass"] = pass

		# Connection problems are dealt with at a higher level
		connect()

		begin
			smb_login()
		rescue ::Rex::Proto::SMB::Exceptions::LoginError => e

			case e.error_reason
			when 'STATUS_LOGON_FAILURE'
				# Nothing interesting
				vprint_status("#{rhost} - FAILED LOGIN (#{smb_peer_os}) #{user} : #{pass} (#{e.error_reason})")
				disconnect()
				return

			when 'STATUS_ACCOUNT_DISABLED'
				report_note(
					:host	=> rhost,
					:proto	=> 'smb',
					:port   =>  datastore['RPORT'],
					:type   => 'smb.account.info',
					:data   => {:user => user, :status => "disabled"},
					:update => :unique_data
				)

			when 'STATUS_PASSWORD_EXPIRED'
				report_note(
					:host	=> rhost,
					:proto	=> 'smb',
					:port   =>  datastore['RPORT'],
					:type   => 'smb.account.info',
					:data   => {:user => user, :status => "expired password"},
					:update => :unique_data
				)

			when 'STATUS_ACCOUNT_LOCKED_OUT'
				report_note(
					:host	=> rhost,
					:proto	=> 'smb',
					:port   =>  datastore['RPORT'],
					:type   => 'smb.account.info',
					:data   => {:user => user, :status => "locked out"},
					:update => :unique_data
				)
			end
			print_status("#{rhost} - FAILED LOGIN (#{smb_peer_os}) #{user} : #{pass} (#{e.error_reason})")

			disconnect()
			return :skip_user # These reasons are sufficient to stop trying.
		end

		if(simple.client.auth_user)
			print_good("#{rhost} - SUCCESSFUL LOGIN (#{smb_peer_os}) '#{user}' : '#{pass}'")
			report_hash = {
				:host	=> rhost,
				:proto	=> 'smb',
				:user	=> user,
				:target_host	=> rhost,
				:target_port	=> datastore['RPORT'],
				:critical       => true
			}
			if pass =~ /[0-9a-fA-F]{32}:[0-9a-fA-F]{32}/
				report_hash.merge!({:hash => pass})
			else
				report_hash.merge!({:pass => pass})
			end
			report_auth_info(report_hash)
		else
			# Samba has two interesting behaviors:
			# 1) Invalid users receive a guest login
			# 2) Valid users return a STATUS_LOGON_FAILURE
			unless(smb_peer_os == 'Unix')
				# Print the guest login message only for non-Samba
				print_status("#{rhost} - GUEST LOGIN (#{smb_peer_os}) #{user} : #{pass}")
			end
		end

		disconnect()
		# If we get here then we've found the password for this user, move on
		# to the next one.
		return :next_user
	end

end

