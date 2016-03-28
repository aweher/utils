#!/bin/bash
if [ ! -f /sql/replication.tar.gz ]; then
	echo "Cannot find the file replication.tar.gz in /sql"
	exit 1
fi
MYPASSWORD=`cat /root/.my.cnf | grep password | cut -d '=' -f 2`
FECHA=`date +%Y-%m-%d-%H-%M-%S`
service mysql stop
mv /var/lib/mysql /var/lib/mysql.${FECHA}
mkdir /var/lib/mysql
cd /var/lib/mysql && tar xzfvi /sql/replication.tar.gz
cd /var/lib/mysql && innobackupex --apply-log --ibbackup=xtrabackup \
   ./  && chown -R mysql:mysql /var/lib/mysql
service mysql start
ARCHIVO=`cat /var/lib/mysql/xtrabackup_binlog_info | awk '{print $1}'`
POSICION=`cat /var/lib/mysql/xtrabackup_binlog_info | awk '{print $2}'`
mysql -p"$MYPASSWORD" -e "reset slave;"
mysql -p"$MYPASSWORD" -e "CHANGE MASTER TO MASTER_HOST='mymaster', MASTER_USER='slaveuser',MASTER_PASSWORD='bFQ!7skp49C8&c75', MASTER_LOG_FILE='$ARCHIVO', MASTER_LOG_POS=$POSICION;"
mysql -p"$MYPASSWORD" -e "start slave;"
echo -n
echo "Esperando 10 segundos para que el slave se sincronice con el master"
sleep 10
mysql -p"$MYPASSWORD" -e "show slave status\G" | less
rm -rf /sql/replication.tar.gz
tar cfvj /srv/backups/mysql/mysql-replication-roto.${FECHA}.tar.bz2 /var/lib/mysql.${FECHA}
rm -rf /var/lib/mysql.${FECHA}
