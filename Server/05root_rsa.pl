=b
This script helps to build the passwordless ssh longin to each node by root account. Developed by Prof. Shin-Pon Ju at NSYSY
2019/12/30
Nodes_IP.txt shows all node IPs. 
=cut
#!/usr/bin/perl

use strict;
use warnings;
use Expect;  
use Parallel::ForkManager;
use MCE::Shared;

my $expectT = 30;# time peroid for expect
my $forkNo = 30;
$ENV{TERM} = "vt100";
my $pass = "123"; ##For all roots of nodes

open my $ss1,"< ./Nodes_IP.dat" or die "No ./Nodes_IP.dat to open.\n $!";
my @temp_array = <$ss1>;
close $ss1; 
my @avaIP=grep (($_!~m{^\s*$|^#}),@temp_array); # remove blank lines and comment lines
for (@avaIP){
	$_  =~ s/^\s+|\s+$//;
}

system("rm -rf /root/\.ssh/*");# remove unexpect thing first (old ssh records)
chdir("/root/.ssh");
system("ssh-keygen -t rsa -N \"\" -f id_rsa");
system("cp id_rsa.pub authorized_keys");
system("chmod 700 /root/\.ssh");
system("chmod 640 /root/\.ssh/authorized_keys");
system("perl -p -i.bak -e 's/.*GSSAPIAuthentication.+/GSSAPIAuthentication no/;' /etc/ssh/sshd_config");
system("perl -p -i.bak -e 's/.*UseDNS.+/UseDNS no/;' /etc/ssh/sshd_config");
system("/etc/init.d/sshd restart");
#### make .ssh directory of each node
#$quality = MCE::Shared->array;
my $pm = Parallel::ForkManager->new("$forkNo");
for (@avaIP){	
$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");
	$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");                            
								exp_continue;
							}
					],
					[
						qr/connecting \(yes\/no\)/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
							}
					]
		); # end of exp 
	#the response after (yes/no)
	#Warning: Permanently added '192.168.0.2' (ECDSA) to the list of known hosts.
	#root@192.168.0.2's password:
				$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");      
							}
					]);	
	
	$exp->send ("\n");
	$exp -> send("rm -rf /root/\.ssh\n") if ($exp->expect($expectT,'#'));
   	$exp -> send("mkdir  /root/\.ssh\n") if ($exp->expect($expectT,'#'));
    $exp -> send("chmod 700 /root/\.ssh\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
$pm->finish;
} # end of loop

$pm->wait_all_children;
# Beign scp

for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("scp  /root/\.ssh/authorized_keys root\@$_:/root/\.ssh/ \n");
    $exp->expect($expectT,[
                    qr/password:/i,
                    sub {
                            my $self = shift ;
                            $self->send("$pass\n");                            
                            exp_continue;
                           }
                ],
                [
                    qr/connecting \(yes\/no\)/i,
                    sub {
                            my $self = shift ;
                             $self->send("yes\n");					        
                             #Are you sure you want to continue connecting (yes/no)?
                         }
                ]
     ); # end of exp 
#the response after (yes/no)
#Warning: Permanently added '192.168.0.2' (ECDSA) to the list of known hosts.
#root@192.168.0.2's password:
               $exp->expect($expectT,[
                    qr/password:/i,
                    sub {
                            my $self = shift ;
                            $self->send("$pass\n");      
                        }
                ]);
	
	
#}
    $exp -> send("\n");
    $exp -> send("chmod 640 /root/\.ssh/authorized_keys\n") if ($exp->expect($expectT,'#'));
   	$exp -> send("/etc/init.d/sshd restart\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
}# for loop

$pm->wait_all_children;

######## go through each node for the final passworless setting

for (@avaIP){	
	$pm->start and next;
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh -l root $_ \n");
	$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");                            
								exp_continue;
							}
					],
					[
						qr/connecting \(yes\/no\)/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
							}
					]
		); # end of exp 
	#the response after (yes/no)
	#Warning: Permanently added '192.168.0.2' (ECDSA) to the list of known hosts.
	#root@192.168.0.2's password:
				$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");      
							}
					]);	
	
	$exp->send ("\n") if ($exp->expect($expectT,'#'));;
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop

$pm->wait_all_children;

######## go through each node for the final passworless setting

for (@avaIP){
	$pm->start and next;
	$_ =~/192.168.0.(\d{1,3})/;#192.168.0.X
    my $temp= $1 - 1;
    my $nodeindex=sprintf("%02d",$temp);
    my $nodename= "node"."$nodeindex";
    print "**$_ --> $nodename**\n";
	my $exp = Expect->new;
	$exp = Expect->spawn("ssh $nodename \n");
	$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");                            
								exp_continue;
							}
					],
					[
						qr/connecting \(yes\/no\)/i,
						sub {
								my $self = shift ;
								$self->send("yes\n");	#first time to ssh into this node				        
								#Are you sure you want to continue connecting (yes/no)?
							}
					]
		); # end of exp 
				$exp->expect($expectT,[
						qr/password:/i,
						sub {
								my $self = shift ;
								$self->send("$pass\n");      
							}
					]);	
	
	$exp->send ("\n") if ($exp->expect($expectT,'#'));
	$exp -> send("exit\n") if ($exp->expect($expectT,'#'));
	$exp->soft_close();
	$pm->finish;
} # end of loop
$pm->wait_all_children;
print "\n\n***###05root_rsa.pl: root passwordless setting done******\n\n";
