#!/bin/bash

#set -e

ts=`date +%s`
let hour_dump=$ts-3600

MONGODUMP_PATH="/usr/bin/mongodump"
MONGO_HOST="52.49.15.158"
MONGO_PORT="27017"
replpass="MQPPr4FAB9Tq8Vpp"
TIMESTAMP=`date +%F-%Hh`

if [ ! -d /igov/scripts/dump ]; then
    mkdir /igov/scripts/dump
fi

$MONGODUMP_PATH --authenticationDatabase admin -u repladmin -p $replpass -d local --host $MONGO_HOST --port $MONGO_PORT -o /igov/scripts/dump/local -c oplog.rs -q "{ts : { \"\$gte\" : { \"\$timestamp\" : { \"t\" : $hour_dump, \"i\" : 0 }}}}"

# Add timestamp to backup
mv /igov/scripts/dump/local /tmp/inc-mongodb-$TIMESTAMP
tar cvzf /tmp/mongodb-inc-$TIMESTAMP.tar.gz /tmp/inc-mongodb-$TIMESTAMP

mv /tmp/mongodb-inc-$TIMESTAMP.tar.gz /backup/mongo/test.db-all.igov.org.ua/hourly

# Upload to Storage
scp /backup/mongo/test.db-all.igov.org.ua/hourly/mongodb-inc-$TIMESTAMP.tar.gz sybase@log.igov.org.ua:/backup/mongo/test.db-all.igov.org.ua/hourly/

# Remove tmp dump
rm -rf /tmp/inc-mongodb-*
rm -rf /igov/scripts/dump
