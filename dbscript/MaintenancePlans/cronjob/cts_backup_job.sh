#!/bin/bash
########## BACKUP variables
CTS_DIR=/var/cts
LOGIN_BACKUP=slave-login
LOGIN_LOG=master-login
CONTAINER_NAME=cts_slave_mysql80
LOG_DB=CTS_Log
RUN_DATE=$(date +%Y-%m-%d)
BK_DIR=/var/cts/dump/mysql
ERROR_CODE=0
ZIP_MODE=1

########## LOAD cts backup function
source ${CTS_DIR}/backup/backup_full_function.sh

######### START backup process
echo "CTS backup full RUN_DATE: ${RUN_DATE}"

# LIST dbs to backup
databases=("CTS_Admin" "CTS_DataCenter" "DCS_DataCenter")
for backup_dbname in "${databases[@]}"
do
   echo "$(date +%Y-%m-%d-%H:%M:%S) >> START backing up ... $backup_dbname"
   
   BACKUP_PATH="$BK_DIR/${backup_dbname}_$(date +%Y%m%d%H%M%S).sql"
   if [ "$ZIP_MODE" = "1" ]
   then
        BACKUP_PATH="${BACKUP_PATH}.gz"
   fi

   result=$(process_full_backup $CONTAINER_NAME \
       $BACKUP_PATH \
       $LOGIN_BACKUP \
       $backup_dbname \
       $LOGIN_LOG \
       $LOG_DB \
       $RUN_DATE \
       $ZIP_MODE)
       ERROR_CODE=$?

    echo "$(date +%Y-%m-%d-%H:%M:%S) >> END backing up $backup_dbname: $result"
done


