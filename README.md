# gcp

 "Global Command Pusher (gcp)" - September 2017
 Written & Maintained by: Will Phan <wp@escnerd.com>
 This Tcl/expect script is used to push different sets of configurations
 based on a host's vendor. Currently the script will handle the following
 vendors:
 	(1) Arista EOS
 	(2) Cisco IOS
 	(3) Juniper JunOS
 	(4) ArubaOS
 	(5) Cisco Nexus
  
 Usage Syntax:
 	./gcp.tcl <hosts> <arista> <cisco> <juniper> <nexus> <Comment>
 Arguments Details:
 
 [0] hosts		- text file containing a list of hosts or IP addresses
 [1] arista 	- text file with a list of EOS commands to push
 [2] cisco 	- text file with a list of IOS commands to push
 [3] juniper 	- text file with a list of JunOS commands to push
 [4] aruba 	- text file with a list of Aruba commands to push
 [5] nexus 	- text file with a list of Nexus commnads to push
 [6] comment	- A comment string that will also be pushed. (CHNGE MGMT)
 
I wrote this script to perform mass configuration changes to 1000's of devices, as there weren't any tools available internally to my prior role that would allow our team members to support us with such assignments.

Initially, I have tried writing the script in Perl, though I've run into issues with how it handles certain scenariors. I have learned that Tcl/ecpect does work as you would "expect" it to, pun intended.
