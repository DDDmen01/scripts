#!/usr/bin/env bash

rm -rf ./conf
rm -rf /tmp/_repo_
git clone git@iSystem.github.com:e-government-ua/iSystem.git /tmp/_repo_
cp -r /tmp/_repo_/scripts_etc/postgres_backup/conf /home/centos/scripts/
rm -rf /tmp/_repo_

. $HOME/.bashrc

cd `dirname $0`

curdate=`date +%Y%m%d`
sourcedb=conf/dblist
dumpstore=/backup/dumps
dbcount=0
PATH=/home/centos/scripts/pgsql_9.4.1/bin:$PATH
do_dump() {

  curtime=`date +%H:%M`

  dbuser=$1
  dbpass=$2
  dbname=$3
  dbhost=$4
  dbport=$5
  storetime=$6
  export PGPASSWORD="$dbpass"
  mkdir -p $dumpstore/$dbname_$dbhost
  find $dumpstore/$dbname'_'$dbhost -maxdepth 1 -type f -mtime `echo $storetime` | grep "$dbname" | while read olddump; do
    echo "Remove old dump: $olddump"
    rm -rf $olddump;
  done
  dump_start=`date +'%Y-%m-%d_%H:%M:%S.%N'`
  pg_dump -U $dbuser -h $dbhost -p $dbport -c $dbname -Fc -f $dumpstore/$dbname'_'$dbhost/$curdate.sql
  dump_stop=`date +'%Y-%m-%d_%H:%M:%S.%N'`
  echo "DUMP: $dbname[$dbhost] Start: $dump_start Stop: $dump_stop"
  let dbcount+=1
  unset PGPASSWORD
}

# MAIN BODY
if [[ "$#" -eq 2 ]] || [[ ! "$1" == "" ]] || [[ ! "$2" == "" ]]; then
    do_dump $(cat $sourcedb | egrep -v "^#|''" | egrep "$1.*$2")
else
while read line; do
    if [[ -z $line ]] || [[ "$line" == "" ]] || [[ "$line" =~ ^#.* ]]; then continue; fi
    do_dump $line
done < $sourcedb
fi
exit 0
