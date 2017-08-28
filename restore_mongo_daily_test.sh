#!/bin/bash

#set -e

MONGORESTORE_PATH="/bin/mongorestore"
MONGO_HOST="test.db-all.igov.org.ua"
MONGO_PORT="27017"
MONGO_USER="repladmin"
MONGO_PWD="8BQ655bBQC"
BACKUP_DIR="/backup/mongo/test.db-all.igov.org.ua/daily"
TIMESTAMP=`date +%F`
TMPDIR=$(mktemp -d)
BACKUP_FILE=$(ls -t $BACKUP_DIR | head -1)

if [ ! -z $1 ]; then
    if [ -f $BACKUP_DIR/$1 ]; then
        BACKUP_FILE=$1
    else
        echo "Backup file not found!"
        exit 1
    fi
fi

echo "This script will extract and restore backup from $BACKUP_DIR/$BACKUP_FILE file."
echo "Target server is $MONGO_HOST"
read -p "Are you sure? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cd $BACKUP_DIR
    tar zxvf $BACKUP_FILE -C $TMPDIR
    $MONGORESTORE_PATH --host $MONGO_HOST:$MONGO_PORT --authenticationDatabase=admin -u $MONGO_USER -p $MONGO_PWD --objcheck --drop --maintainInsertionOrder $TMPDIR
    echo "restoring..."
    ls $TMPDIR
    rm -rf $TMPDIR
fi
