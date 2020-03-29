#!/usr/bin/perl
#munge setting for nodes developed by Prof. Shin-Pon Ju 2020/01/09
use strict;
use warnings;
use Expect;
use Parallel::ForkManager;
my $expectT = 30;# time peroid for expect
my $forkNo = 30;
my $pm = Parallel::ForkManager->new("$forkNo");

open my $ss,"< ./Nodes_IP.dat" or die "No Nodes_IP.dat to read"; 
my @temp_array=<$ss>;
close $ss; 
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
chomp @avaIP;

# find all IPs of available nodes 
$ENV{TERM} = "vt100";
my $pass = "123"; ##For all roots of nodes

for (@avaIP){	
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**nodename**:$nodename\n";
    system("scp  /etc/munge/munge\.key root\@$nodename:/etc/munge/");
    if ($? != 0){print "BAD: scp  /etc/munge/munge\.key root\@$nodename:/etc/munge/ failed\n";};    
    sleep(1);
    my $response = `ssh $nodename \'ls -al /etc/munge/\'`;
	print "ssh $nodename response: $response\n";	
    $pm->finish;
} # end of loop
$pm->wait_all_children;
sleep(1);

for (@avaIP){	
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**nodename**:$nodename\n";
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename\n");	
	$exp->send ("chown munge: /etc/munge/munge.key\n") if ($exp->expect($expectT,'#'));
	$exp->send ("chmod 400 /etc/munge/munge.key\n") if ($exp->expect($expectT,'#'));
	$exp->send ("systemctl enable munge\n") if ($exp->expect($expectT,'#'));
	$exp->send ("systemctl start munge\n") if ($exp->expect($expectT,'#'));
	$exp->send ("munge -n\n") if ($exp->expect($expectT,'#'));
	$exp->send ("munge -n| unmunge \n") if ($exp->expect($expectT,'#'));	
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
    $pm->finish;
}
$pm->wait_all_children;
sleep(1);
print "***** WATCH OUT!!!!!\n";
print "***** Begin munge ssh decode check node by node!!!!!\n\n";
sleep(3);

for (@avaIP){	
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
	my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**nodename**:$nodename\n";
	system("munge -n \| ssh $nodename unmunge");
	#$pm->finish;
}# for loop

