#!/usr/bin/perl
use strict;
use warnings;

system("killall -9 yum");
system("rm -rf /var/run/yum.pid");
#system('yum -y groupinstall "Development Tools"');

my @package = ("vim", "wget", "net-tools", "epel-release", "htop", "make"
			, "gcc-c++", "nfs-utils", "ypserv" ,"yp-tools", "gcc-gfortran","geany","psmisc"
			, "ypbind" , "rpcbind",,"perl-MCE-Shared",
			"perl-Parallel-ForkManager","xauth");

for (@package){system("yum -y install $_");}
system("perl -p -i.bak -e 's/.*GSSAPIAuthentication.+/GSSAPIAuthentication no/;' /etc/ssh/sshd_config");
system("perl -p -i.bak -e 's/.*UseDNS.+/UseDNS no/;' /etc/ssh/sshd_config");
system("/etc/init.d/sshd restart");
system("yum -y upgrade");
