#!/bin/bash

#set -e

MONGODUMP_PATH="/usr/bin/mongodump"
MONGO_HOST="52.49.15.158" #replace with your server ip
MONGO_PORT="27017"
MONGO_USER="repladmin"
MONGO_PWD="MQPPr4FAB9Tq8Vpp"
TIMESTAMP=`date +%F`
DAY=4

mkdir /tmp/$TIMESTAMP
$MONGODUMP_PATH -h $MONGO_HOST:$MONGO_PORT -u $MONGO_USER -p $MONGO_PWD -o /tmp/$TIMESTAMP

#mongo admin --eval "printjson(db.fsyncUnlock())"

mv /tmp/$TIMESTAMP /tmp/mongodb-$TIMESTAMP
cd /tmp/mongodb-$TIMESTAMP
tar cvzf /backup/mongo/test.db-all.igov.org.ua/daily/mongodb-daily-$TIMESTAMP.tar.gz *

scp /backup/mongo/test.db-all.igov.org.ua/daily/mongodb-daily-$TIMESTAMP.tar.gz sybase@log.igov.org.ua:/backup/mongo/test.db-all.igov.org.ua/daily/ && \
ssh sybase@log.igov.org.ua "find /backup/mongo/test.db-all.igov.org.ua/daily -type f -mtime +10 -exec rm -f {} \;" && \
ssh sybase@log.igov.org.ua "find /backup/mongo/test.db-all.igov.org.ua/hourly -type f  -exec rm -f {} \;"

find /backup/mongo/test.db-all.igov.org.ua/daily -type f -mtime +$DAY -exec rm -f {} \;
find /backup/mongo/test.db-all.igov.org.ua/hourly -type f  -exec rm -f {} \;

rm -rf /tmp/mongodb-*
