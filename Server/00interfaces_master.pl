#CentOS 7 one click to set up Server
########## Things to know first 
#1. You need to check the internet card name before installation (ls /etc/sysconfig/network-scripts|grep ifcfg-*)
#ifup ifcfg-enp0s3 (if the internet card cfg file is ifcfg-enp0s3)
#yum -y install net-tools
##****** perl -v to make sure Perl has been installed!!!!!!!!!!!!
#2. try ip addr

## basic setting
#!/usr/bin/perl

use strict;
use warnings;
use Cwd; #Find Current Path

system("systemctl stop NetworkManager");
system("systemctl disable NetworkManager");

#Reading required information for Server 
open my $ss,"< ./Server_setting.dat" or die "No Server_setting.dat to open.\n $!";
my @temp_array = <$ss>;
close $ss; 

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
# set the domain name for our cluster
system("domainname $ServerSetting{domainname}");
system("hostname master");
system("echo master > /etc/hostname");
system("hostnamectl set-hostname master");# set permanent hostname 
system("nisdomainname $ServerSetting{domainname}");

# get MAC of each internet card
my %mac;
for ($ServerSetting{if_internet},$ServerSetting{if_private}){
      my $ipne = `ip add show $_`;      
      $ipne =~ /(\w+:\w+:\w+:\w+:\w+:\w+)/;# the first matched item is mac!
      chomp $1;
      $mac{$_}="$1";  
}

#internet setting
if($ServerSetting{machinetype} ne "virtualbox"){
`echo "BOOTPROTO=static" > /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#open a new file
`echo "DNS1=$ServerSetting{dns_nameservers1}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "DNS2=$ServerSetting{dns_nameservers2}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "GATEWAY=$ServerSetting{gateway}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
}
else{
`echo "BOOTPROTO=dhcp" > /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
}

`echo "DEVICE=$ServerSetting{if_internet}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;#append the data into the file
`echo "NAME=$ServerSetting{if_internet}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "IPADDR=$ServerSetting{IP_address}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "NETMASK=$ServerSetting{netmask}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "HWADDR=$mac{$ServerSetting{if_internet}}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`; 
`echo "DEFROUTE=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;
`echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_internet}`;

#private interface setting
`echo "BOOTPROTO=static" > /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "DEVICE=$ServerSetting{if_private}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "NAME=$ServerSetting{if_private}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "IPADDR=192.168.0.101" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "BROADCAST=192.168.0.255" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "HWADDR=$mac{$ServerSetting{if_private}}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`; 
`echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;
`echo "MTU=$ServerSetting{MTU}" >> /etc/sysconfig/network-scripts/ifcfg-$ServerSetting{if_private}`;

#restart networking
for ($ServerSetting{if_internet},$ServerSetting{if_private}){
  system("ifdown $_ ");## stop this NIC and force it to use new seeting by the following command 
  system("ip addr flush dev $_");## remove all previous setting (because we want to assign new informatio)  
  system("ifup $_"); ## use new setting
 }

system("systemctl restart network");
system("systemctl enable network");

### The following packages are for CentOS 7
system("killall -9 yum");
system("rm -rf /var/run/yum.pid");

my @package = ("vim", "wget", "net-tools", "epel-release", "htop", "make"
			, "openssh*", "nfs-utils", "ypserv" ,"yp-tools","geany","psmisc"
			,  "iptables-services", "ypbind" , "rpcbind","perl-Expect","ntp"
			,"perl-MCE-Shared","perl-Parallel-ForkManager","xauth","tmux");
foreach(@package){system("yum -y install $_");}

system("yum -y upgrade");
system("timedatectl set-timezone Asia/Taipei");## setting timezone
system("systemctl stop ntpd");
system("ntpdate pool.ntp.org");
system("systemctl start ntpd ");
system("systemctl enable ntpd");
system ("rm -rf geany-themes");
system ("git clone https://github.com/codebrainz/geany-themes.git");
my $current_path = getcwd;# get the current path dir
chdir("$current_path/geany-themes");
system (" bash install.sh");
print "\n\n***###00interfaces_master.pl: set internet card done******\n\n";
