
#!/bin/bash

SOURCE_DIRECTORY="/sybase/apps/jenkins"
DIRECTORY_TO_BACKUP="/tmp/"  
 
tar -czf /tmp/ci-all-`date "+%Y-%m-%d"`.tar.gz --exclude=workspace/* --exclude=logs/*  --exclude=.cache/* --exclude=.m2/* $SOURCE_DIRECTORY
scp /tmp/ci-all-`date "+%Y-%m-%d"`.tar.gz centos@visor.tech.igov.org.ua:/backup/tech_ci-jenkins
scp /tmp/ci-all-`date "+%Y-%m-%d"`.tar.gz sybase@log-backup.igov.org.ua:/backup/tech_ci-jenkins
rm /tmp/ci-all-`date "+%Y-%m-%d"`.tar.gz

