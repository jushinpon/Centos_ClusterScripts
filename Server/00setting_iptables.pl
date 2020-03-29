#!/usr/bin/perl -w
#***systemctl status iptables: check iptables service status
#***iptables -nLv: check the current iptables setting
#http://linux.vbird.org/linux_server/0250simple_firewall.php
#https://www.itread01.com/content/1500003489.html
#https://www.opencli.com/linux/iptables-command
# presetting 
# check https://linuxize.com/post/how-to-install-iptables-on-centos-7/
use strict;
use warnings;

#Reading required information for Server 
open my $ss1,"< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss1>;
close $ss1; 
my @temp_array1=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines
my % ServerSetting; # keep all information for Server setting
for (@temp_array1){
	$_  =~ s/^\s+|\s+$//;
	my @temp = split (/=/,$_) ;
	$temp[0]  =~ s/^\s+|\s+$//;
	chomp ($temp[0]);
	$temp[1]  =~ s/^\s+|\s+$//;
	chomp ($temp[1]);
	$ServerSetting{$temp[0]} = $temp[1] ;
}

`systemctl stop firewalld`;#stop the FirewallD service
`systemctl disable firewalld`;#Disable the FirewallD service to start automatically on system boot
`systemctl mask --now firewalld`;#Mask the FirewallD service to prevent it from being started
#by another services
system("killall -9 yum");
system("yum install -y iptables-services");
system("systemctl start iptables");
system("systemctl enable iptables");#Enable the Iptables service to start automatically on system boot

# put all IPs allowed SSH login into IPs.dat
open my $ss2,"< IPs.dat" or die "No IPs.dat to read for iptables setting"; 
my @temp_array3=<$ss2>;
close $ss2; 
my @iparray = grep (($_!~m/^\s*$|^#/),@temp_array3); #remove empty lines 

# remove all defined rules first!
`iptables -F`;
`iptables -F -t nat`; 
`iptables -Z`;
`iptables -X`;

system ("iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o $ServerSetting{if_internet} -j MASQUERADE");

#assign policies
`iptables -P INPUT ACCEPT`;# accept all IPs first

foreach (@iparray){
	$_  =~ s/^\s+|\s+$//;
	chomp $_;	
	system ("iptables -A INPUT -s $_ -p tcp --dport 22 -j ACCEPT");
}
system ("iptables -A INPUT -s 192.168.0.0/24 -p tcp --dport 22 -j ACCEPT");
system ("iptables -A INPUT -s 192.168.0.0/24 -p icmp -j ACCEPT");# for ping server
system ("iptables -A INPUT -p icmp -s 127.0.0.1 -j ACCEPT");

system ("iptables -A INPUT -p tcp --dport 22 -j DROP") if (@iparray) ;# if not an empty array for iparray

`iptables-save >  /etc/sysconfig/iptables`; # save the current iptables setting for rebootting

#check: iptables -L -nv
#iptables -t nat -L -nv
