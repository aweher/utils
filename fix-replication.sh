#!/bin/bash
rm -rf /srv/dotsql-to-slave/*.gz
innobackupex --slave-info --stream=tar /tmp/ | gzip -c -1 > /srv/dotsql-to-slave/replication.tar.gz
echo "now please run the script script restore-mysql-replication.sh in the slave node"
