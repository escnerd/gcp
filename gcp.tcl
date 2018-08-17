#!/usr/bin/expect -f
###############################################################################
#
# "Global Command Pusher (gcp)" - September 2017
# Written & Maintained by: Will Phan <willphan.re@gmail.com>
#
# This Tcl/expect script is used to push different sets of configurations
# based on a host's vendor. Currently the script will handle the following
# vendors:
#
# 	(1) Arista EOS
# 	(2) Cisco IOS
# 	(3) Juniper JunOS
# 	(4) ArubaOS
# 	(5) Cisco Nexus
#
# Usage Syntax:
#
# 	./gcp.tcl <hosts> <arista> <cisco> <juniper> <nexus> <Comment>
#
# Arguments Details:
# 
# [0] hosts	- text file containing a list of hosts or IP addresses
# [1] arista 	- text file with a list of EOS commands to push
# [2] cisco 	- text file with a list of IOS commands to push
# [3] juniper 	- text file with a list of JunOS commands to push
# [4] aruba 	- text file with a list of Aruba commands to push
# [5] nexus 	- text file with a list of Nexus commnads to push
# [6] comment	- A comment string that will also be pushed. (CHNGE MGMT)
#
###############################################################################
# When `expecting`, set the timeout value so that it'll wait indefinitely.
set timeout -1

# Perform a short sleep (1/10 second) before every send command
set force_conservative 1
###############################################################################
# Procedures (Functions)
###############################################################################
proc getpass {prompt} {
	# Allows for a hidden password prompt for the user.
	package require Expect
	set oldmode [stty -echo -raw]
	send_user "$prompt"
	expect_user -re "(.*)\n"
	send_user "\n"
	eval stty $oldmode
	return $expect_out(1,string)
}
proc exp_prompt {} {
	# The prompt is often `expected`, hence a `proc` is written for tidyness. 
	expect {
		# One-off fix for 3945's
		"Technolgy" {
			expect {
				"^>" {}
				"^#" {}
			}
		}
		"^>" {}
		"^#" {}
	}
}
proc which_vendor {} {
	# Find out what vendor the host belongs to
	# Default TCL Implementation on Mac is buggy, and for
	# some reason I couldn't used regex to cover both `C` and `c`.
	variable host_ven
	set host_ven unsupported
	send "show version\r"
	expect {
		"JUNOS" {
			set host_ven junos
		}
		"Nexus" {
			set host_ven nexus
		}
		"cisco" {
			set host_ven cisco
		}
		"Cisco" {
			set host_ven Cisco
		}
		"Arista" {
			set host_ven arista
		}
		"ArubaOS" {
			set host_ven aruba
		}
	}
}
proc print_bar {} {
	puts -nonewline stdout "\n#######################################"
	puts -nonewline stdout "#######################################\n"
}
proc completed {hn ven} {
	print_bar
	puts -nonewline stdout "Completed execution for $hn -- Vendor: $ven"
	print_bar
}
proc validation {cmd ven filename} {
	puts "Here are the contents of $fileName:"
	foreach i $cmds {
		puts "$i"
	}
	puts "Are these the correct $ven commands to push? (y/n):"
	set validate_flag [gets stdin]
	if {$validate_flag == "n"} {
		exit
	} elseif {$validate_flag == "y"} {
		# Continue with the rest of the script
	} else {
		# Assumes an invalid value is returned from the user
		exit
	}
}
proc push_and_log {cmds hn ven} {
	send "$cmds\r"
	expect {
		"^*#" {
			set outp_fid [open "tmp/$hn\_$ven\_out.txt" "a"]
			puts $outp_fid "$expect_out(buffer)"
			close $outp_fid
		}
		"^*>" {
			set outp_fid [open "tmp/$hn\_$ven\_out.txt" "a"]
			puts $outp_fid "$expect_out(buffer)"
			close $outp_fid
		}
	}
}
###############################################################################
# Process the passed arguments from the user
###############################################################################
if { $::argc > 6 } {
	#
	# Build an empty list for each vendor to store the commands in.
	# The commands are read from the input files.
	#
	set arista_cmds [list]
	set cisco_cmds [list]
	set juniper_cmds [list]
	set aruba_cmds[list]
	set nexus_cmds [list]

	# Hosts
	set hosts_fid [open "[lindex $argv 0]" "r"]

	# Arista
	set cmd_fid [open "[lindex $argv 1]" "r"]
	while {[gets $cmds_fid i] != -1} {
		lappend arista_cmds $i
	}
	close $cmds_fid
	validation $arista_cmds "Arista EOS" [lindex $argv 1]

	# Cisco
	set cmds_fid [open "lindex $argv 2" "r"]
	while {[gets $cmd_fid i] != -1} {
		lappend cisco_cmds $i
	}
	close $cmds_fid
	validation $cisco_cmds "Cisco IOS" [lindex $argv 2]

	# Juniper
	set cmd_fid [open "[lindex $argv 3]" "r"]
	while {[gets $cmd_fid i] != -1} {
		lappend juniper_cmds $i
	}
	close $cmds_fid
	validation $juniper_cmds "Juniper JunOS" [lindex $argv 3]

	# Aruba
	set cmd_fid [open "[lindex $argv 4]" "r"]
	while {[gets $cmd_fid i] != -1} {
		lappend arista_cmds $i
	}
	close $cmds_fid
	validation $aruba_cmds "ArubaOS" [lindex $argv 4]

	# Nexus
	set cmd_fid [open "[lindex $argv 5]" "r"]
	while {[gets $cmd_fid i] != -1} {
		lappend nexus_cmds $i
	}
	close $cmds_fid
	validation $nexus_cmds "Cisco Nexus" [lindex $argv 5]

	# Comment (Change MGMT)
	set CR_num [lindex $argv 6]
} else {
	puts "Not enough arguments passed!"
	puts "Example: ./gcp.tcl hosts arista cisco juniper aruba nexus comment"
	exit
}
###############################################################################
# Body
###############################################################################
set PassW [getpass "Enter your TACACS account password: "]

# Iterate through each host in the hosts file
while {[gets $hosts_fid hostname] != -1} {
	spawn ssh -o "StrictHostKeyChecking no" $hostname
	expect {
		# Proceed as usual
		"*assword:"	{
			send "$PassW\r"
		}
		# Sometimes we'll encounter older firmware that doesn't suppport v2 SSH
		"2 vs\. 1"	{
			spawn ssh -o "StrictHostKeyChecking no" $hostname -1
			expect "*assword:" {
				send "$PassW\r"
			}
		}
		# Sometimes DNS has issues resolving
		"Could not resolve hostname" {
			set outp_fid [open "tmp/$hostname\_skip.txt" "w"]
			puts "$outp_fid $hostname skipped -- Could not resolve hostname in DNS."
			close $outp_fid
			sleep .2
			continue
		}
	}

	# Stamp the CR with the comment and disable paging limits for this session
	expect {
		"^*>" {
			# Junos Prompt detected
			send "\#show host $CR_num\r"
			exp_prompt
		}
		"^*#" {
			# Either Arista, Cisco, Aruba, Nexus prompt
			send "show host $CR_num\r"
			exp_prompt
			send "term length 0\r"
			expect {
				# Aruba takes a different command to disable paging limits
				# How we determine if it's an Aruba devices is with this string:
				"Invalid input" {
					send "no paging\r"
					exp_prompt
				}
				"^*>" {}
				"^*+" {}
			}
		}
		"*assword:" {
			# The current iterated device is not taking the user's password.
			set outp_fid [open "tmp/$hostname\_skip.txt" "w"]
			puts $outp_fid "$hostname skipped--Credentials did not work."
			close $outp_fid
			send \003
			sleep .2
			continue
		}
	}

	# Find out which vendor the current iterated host is
	# The vendor value is then stored into $host_ven
	which_vendor
	exp_prompt

	# Execute a specific set of commands per vendor type of host
	if {$host_ven == "junos"} {
		foreach c $juniper_cmds {
			push_and_log $c $hostname $host_ven
		}
	} elseif {$host_ven == "cisco"} {
		foreach c $cisco_cmds {
			push_and_log $c $hostname $host_ven
		}
	} elseif {$host_ven == "arista"} {
		foreach c $arista_cmds {
			push_and_log $c $hostname $host_ven
		}
	} elseif {$host_ven == "aruba"} {
		foreach c $nexus_cmds {
			push_and_log $c $hostname $host_ven
		}
	} elseif {$host_ven == "nexus"} {
		foreach c $nexus_cmds {
			push_and_log $c $hostname $host_ven
		}
	} else {
		puts stdout "\nThis Vendor is NOT supported and will be skipped\n"
	}
	
	# Logout of the current host and wait 0.2 seconds
	# This sometimes prevents errors as the script will issue
	# out commands faster than the prompt is ready to take
	send "exit\r"
	sleep .2

	# `completed` `proc` prints the hostname and vendor between two bars
	completed $hostname $host_ven
}
close $hosts_fid
exit
