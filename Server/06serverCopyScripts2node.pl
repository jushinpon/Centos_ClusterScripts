=beg
This Perl script uses the Expect module to scp all required Perl scripts from server to each node after you assign the private IP
for all nodes. We put all scripts in the directory "ForNode".-- developed by Prof. Shin-Pon Ju at NSYSU (11/28/2019)
=cut
#!/usr/bin/perl
use strict;
use warnings;
use Expect;
use Cwd; #Find Current Path
use Parallel::ForkManager;

my $current_path = getcwd;# get the current path dir
$current_path =~ s/\/Server//;# get the path for node scripts (ForNode)
my $expectT = 30;# time peroid for expect
my $forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");

$ENV{TERM} = "vt100";
my $pass = "123"; ##For all roots of nodes

open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
close $ss; 

for (@avaIP){	
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**nodename**:$nodename\n";
    system("ssh $nodename \'rm -rf /root/*.pl\'");
 if ($? != 0){print "BAD: ssh $nodename \'rm -f /root/*.pl\' failed\n";};    
    system("ssh $nodename \'rm -rf /root/*.txt\'");
 if ($? != 0){print "BAD: ssh $nodename \'rm -rf /root/*.txt\' failed\n";};    
    sleep(1);
    system("scp  $current_path/ForNode/* root\@$nodename:/root");
 if ($? != 0){print "BAD: scp  $current_path/ForNode/* root\@$nodename:/root failed\n";};    
    sleep(1);
    system("scp  $current_path/Server/Server_setting.dat root\@$nodename:/root");
 if ($? != 0){print "BAD: scp  /Server/Server_setting.dat root\@$nodename:/root failed\n";};    

	system("ssh $nodename \'rm -rf nohup.out\'");
 if ($? != 0){print "BAD: ssh $nodename \'rm -rf nohup.out\' failed\n";};    
    sleep(1);
    my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename");
	$exp->send ("nohup perl oneclick_slave.pl & \n") if ($exp->expect($expectT,'#'));# nohup perl can't be done by ssh nodeXX ''
	$exp -> send("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
    $pm-> finish;
}# for loop
$pm->wait_all_children;

print "\n\n***###06serverCopyScripts2node.pl: Copy scripts to each node done******\n\n";
