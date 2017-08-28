#!/bin/bash
 
SOURCE_DIRECTORY="/sybase/apps/jenkins/jobs"
DIRECTORY_TO_BACKUP="/tmp/"
 
tar -czf /tmp/ci-jobs-`date "+%Y-%m-%d"`.tar.gz --exclude=workspace/*  --exclude=builds/* --exclude=scm-pooling.log $SOURCE_DIRECTORY
scp /tmp/ci-jobs-`date "+%Y-%m-%d"`.tar.gz centos@visor.tech.igov.org.ua:/backup/tech_ci-jenkins
scp /tmp/ci-jobs-`date "+%Y-%m-%d"`.tar.gz sybase@log-backup.igov.org.ua:/backup/tech_ci-jenkins
rm /tmp/ci-jobs-`date "+%Y-%m-%d"`.tar.gz
