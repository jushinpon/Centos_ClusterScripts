## You Need install ypbind yp-tools ypserv rpcbind first
## yum -y install ypbind yp-tools ypserv rpcbind 
#!/usr/bin/perl
use strict;
use warnings;

`ypdomainname melcluster`;
`echo "NISDOMAIN=melcluster" > /etc/sysconfig/network`;
`echo "domain melcluster server master" > /etc/yp.conf`;
`authconfig --enablenis --nisdomain=melcluster --nisserver=master --enablemkhomedir --update`;
system("systemctl start rpcbind ypbind");
system("systemctl enable rpcbind ypbind");
system("systemctl restart rpcbind ypbind");
`setsebool -P use_nfs_home_dirs 1`;
