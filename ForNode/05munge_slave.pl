#SLURM slave installation script developed by Prof. Shin-Pon Ju 2019/12/15

#Munge is an authentication tool used to identify messaging from the Slurm machines
#!/usr/bin/perl
use strict;
use warnings;

system("yum install yum-utils -y");
system("yum-complete-transaction --cleanup-only");
system("package-cleanup --dupes");
system("package-cleanup --problems");
system("yum install epel-release -y\n");
system("yum upgrade -y\n");

system("systemctl stop munge");
system("killall munged");

system("yum remove  munge munge-libs munge-devel -y");
sleep(1);

if(`grep 'slurm' /etc/passwd`){#remove the old slurm account
	system("userdel -r slurm");
}

if(`grep 'munge' /etc/passwd`){#remove the old slurm account
	print "**Response from grep 'munge' /etc/passwd: True \n";
	my $temp = `userdel -r munge`;
	print "**Response from userdel -r munge: $temp \n"; #empty is good
		if($temp=~/currently used by process (\d+)/){
			`kill $1`;
			`userdel -r munge`;
			}
}
### End of removing old slurm setting
=b
Create the global users:
Slurm and Munge require consistent UID and GID across every node in the cluster.
=cut

#For all the nodes, before you install Slurm or Munge:
my $MUNGEUSER=991;
`groupadd -g $MUNGEUSER munge`;
`useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge`;
my $SLURMUSER=992;
`groupadd -g $SLURMUSER slurm`;
`useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm`;

#install Munge (for all nodes and server)
system("rm -rf /etc/munge");
system("rm -rf  /var/log/munge");
system("rm -rf  /var/lib/munge");

system("yum install munge munge-libs munge-devel -y");
sleep(2);
system("chown -R munge: /etc/munge/ /var/log/munge/");
system("chmod 0700 /etc/munge/ /var/log/munge/");
system("chmod 0711 /var/lib/munge/");
print "*****munge installation done \n";

