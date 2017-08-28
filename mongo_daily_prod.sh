#!/bin/bash

#set -e

MONGODUMP_PATH="/usr/bin/mongodump"
MONGO_HOST="mongo.igov.org.ua"
MONGO_PORT="27017"
MONGO_USER="sitesc"
MONGO_PWD="JHnHxApbfp6jru8F"
TIMESTAMP=`date +%F`
TMPDIR=$(mktemp -d)
DAY=2

mkdir $TMPDIR/$TIMESTAMP
$MONGODUMP_PATH -h $MONGO_HOST:$MONGO_PORT -d e-gov -u $MONGO_USER -p $MONGO_PWD -o $TMPDIR/$TIMESTAMP

#mongo admin --eval "printjson(db.fsyncUnlock())"

mv $TMPDIR/$TIMESTAMP $TMPDIR/mongodb-$TIMESTAMP
cd $TMPDIR/mongodb-$TIMESTAMP
tar cvzf /backup/mongo/mongo.igov.org.ua/daily/mongodb-daily-$TIMESTAMP.tar.gz *

scp /backup/mongo/mongo.igov.org.ua/daily/mongodb-daily-$TIMESTAMP.tar.gz sybase@log.igov.org.ua:/backup/mongo/mongo.igov.org.ua/daily/ && \
ssh sybase@log.igov.org.ua "find /backup/mongo/mongo.igov.org.ua/daily -type f -mtime +3 -exec rm -f {} \;"

find /backup/mongo/mongo.igov.org.ua/daily -type f -mtime +$DAY -exec rm -f {} \;

rm -rf $TMPDIR
