=b
1. rm nohup.out
2. nohup one_click_server.pl &
The SLURM should be installed after our cluster is basically assembled.  (after all nodeXX.txt files are shown in /home
06munge_server.pl
07slurm_server.pl

Required txt files
1. Nodes_IP.txt: required txt file to indicate all your node IPs (more convenient for installing new nodes)->
 for a brand new cluster, 05root_rsa.pl builds one for you.
 2. IPs.txt: all accepted IPs you want to use for iptables  
=cut
use strict;
use warnings;

system("rm -f /home/node*.txt");
my @ser_array = ("00interfaces_master.pl","00setting_iptables.pl","01rc_local.pl"
			   ,"02hosts.pl","03NFS.pl","04NIS.pl","05root_rsa.pl","06serverCopyScripts2node.pl");
foreach(@ser_array){
	print "****Execute Perl script: $_ \n";
	system("perl $_");
	sleep(1);
}

#### NFS check
print "\n\n***** NFS check******\n";
system("showmount -e");

print "\n\n***** NFS 2049 port connection check******\n";
system ("netstat -ntu|grep 2049");

#### NIS check
print "\n\n***** NIS check******\n";
system("yptest");

####date check

print "\n\n***** date check******\n";
system("date");
print "\n\nIf you see all nodeXX.txt files in /home, you may begin to set the slurm.\n\n";
