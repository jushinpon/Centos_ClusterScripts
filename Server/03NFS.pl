#!/usr/bin/perl

use strict;
use warnings;

system("perl -p -i.bak -e 's/.+RPCNFSDCOUNT.+/RPCNFSDCOUNT=128/;' /etc/sysconfig/nfs");
#system("service nfs start");
############### NFS share Folder ###################
#system("mkdir /work");
`chmod -R 755 /home`;
`chmod -R 755 /opt`;

############### exports file setting ###################
#/home
`echo "/home 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" > /etc/exports`;
#/opt
`echo "/opt 192.168.0.0/24(rw,no_root_squash,no_subtree_check,async)" >> /etc/exports`;

`systemctl enable rpcbind`;
`systemctl enable nfs-server`;#systemctl enable nfs`  the same
`systemctl enable nfs-lock`;#to avoid race conditions 
`systemctl enable nfs-idmap`;

`systemctl start rpcbind`;
`systemctl start nfs-server`;#`systemctl start nfs` the same
`systemctl start nfs-lock`;
`systemctl start nfs-idmap`;

system("exportfs -auv"); # umount all first if you have mounted some previously!
system("exportfs -arv"); # make setting work!
print "\n\n***###03NFS.pl: set NFS done******\n\n";

# -v list all shared folders
#-a
########################## 
