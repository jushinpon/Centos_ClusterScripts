#!/usr/bin/perl
#SLURM installation script developed by Prof. Shin-Pon Ju 2019/12/15
# You need to install munge for server and nodes first
use warnings;
use strict;
use Expect;
use Parallel::ForkManager;
use MCE::Shared;
use Cwd; #Find Current Path

my $current_path = getcwd;# get the current path dir
my $expectT = 30;# time peroid for expect
my $forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");
## get available IPs by reading or find them by ssh

system("systemctl stop slurmctld.service");
system("systemctl stop slurmd.service");

open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
chomp @avaIP;
close $ss; 

#install Slurms
my $currentVer = "slurm-19.05.4.tar.bz2";#***** the latest version of this package (check the latest one if possible)
my $URL = "https://download.schedmd.com/slurm/$currentVer";#url to download
my $Dir4download = "slurm_download"; #the directory we download Mpich
#
system ("rm -rf /root/$Dir4download");# remove the older directory first
system("mkdir /root/$Dir4download");# make a new directory for NFS (because the package is needed for each node)
my @slurm_pack = qw(openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel 
rrdtool-devel ncurses-devel fribidi man2html libibmad libibumad perl-ExtUtils-MakeMaker);
#
for (@slurm_pack){
	system("yum -y install $_");
}
system ("yum upgrade");
#
chdir("/root/$Dir4download");
system("wget  $URL");
system("yum install rpm-build -y");
system("rpmbuild -ta $currentVer");
if($? != 0){die "rpmbuild process failed!\n";}
system ("rm -rf /home/slurm_rpms");# remove the older directory first
system("mkdir /home/slurm_rpms");# make a new directory for NFS (because the package is needed for each node)

system("cp /root/rpmbuild/RPMS/x86_64/slurm-*  /home/slurm_rpms/");
chdir("/home/slurm_rpms");
system("yum --nogpgcheck localinstall slurm-* -y");
chdir("$current_path");
$ENV{TERM} = "vt100";
my $pass = "123"; ##For all roots of nodes

######## begin install slurm in each node (need fork in the future)
print "**** Install slurm for each node\n";
for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");	
	$exp->send ("systemctl stop slurmd.service\n") if ($exp->expect($expectT,'#'));
	$exp->send ("cd /home/slurm_rpms\n") if ($exp->expect($expectT,'#'));
	$exp -> send("yum --nogpgcheck localinstall slurm-* -y\n") if ($exp->expect($expectT,'#'));
	$exp -> send("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;
#configure slurm
tie my %coreNo, 'MCE::Shared';
tie my %socketNo, 'MCE::Shared';
tie my %threadcoreNo, 'MCE::Shared';
tie my %coresocketNo, 'MCE::Shared';

#%coreNo;
for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");	
# get CPU Number	
	$exp->send ("lscpu|grep \"^CPU(s):\" | sed 's/^CPU(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	my $Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coreNo{$_} = $Mread;
	  print "coreNo hash array $_ , Mread: $Mread, $coreNo{$_}\n";
	  };
	  
# get socket Number	
	$exp->send ("lscpu|grep \"^Socket(s):\" | sed 's/^Socket(s): *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $socketNo{$_} = $Mread;
	  print "socketNo hash array $_ , Mread: $Mread, $socketNo{$_}\n";
	  };
 # get the thread Number per core 	
	$exp->send ("lscpu|grep \"^Thread(s) per core:\" | sed 's/^Thread(s) per core: *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $threadcoreNo{$_} = $Mread;
	  print "threadcoreNo hash array $_ , Mread: $Mread, $threadcoreNo{$_}\n";
	  };

# get the core Number per socket 	
	$exp->send ("lscpu|grep \"^Core(s) per socket:\" | sed 's/^Core(s) per socket: *//g' \n") if ($exp->expect($expectT,'#'));
	$exp->expect($expectT,'-re','\d+');#before() keeps command, match() keeps number, after() keep left part+root@master#
	$Mread = $exp->match();
	chomp $Mread;
    if ($Mread){
	  $coresocketNo{$_} = $Mread;
	  print "coresocketNo hash array $_ , Mread: $Mread, $coresocketNo{$_}\n";
	  };

	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;
unlink "./IP_coreNo.txt";
open my $ss3,">./IP_coreNo.txt";
print $ss3 "IP  CoreNo SocketNo ThreadPerCore CorePerSocket\n";
for (sort keys %coreNo){
	print $ss3 "$_  $coreNo{$_} $socketNo{$_} $threadcoreNo{$_} $coresocketNo{$_}\n";
	print  "$_  $coreNo{$_} $socketNo{$_} $threadcoreNo{$_} $coresocketNo{$_}\n";
}
close($ss3);

## check slurm installation staus of each node
unlink "./slurm_serverCheck.txt";
open my $ss1,">./slurm_serverCheck.txt"; 

for (@avaIP){	
	#$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**nodename**:$nodename\n";
	
    my $temp1 = `ssh root\@$nodename 'ls -al /etc/slurm'`;
	chomp $temp1;
    print $ss1 "**$nodename: checking info from system call of ls -al-> $temp1\n \$?: $?\n\n";   
}
close($ss1);
print "You need to check slurm_serverCheck.txt to make sure slurm has been install on each node\n";
print "*********If slurm installation is done,You need to configure slurm now!!\n";
