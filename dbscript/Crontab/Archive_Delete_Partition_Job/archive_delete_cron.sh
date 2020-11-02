#! /bin/bash

set -x

#######################################################################################################################
# Install
#  +mysql client 
#  +sshpass
#######################################################################################################################



#######################################################################################################################
# Import common functions, environment variables
#######################################################################################################################
BASEDIR=$(dirname "$0")
source $BASEDIR/common-functions.sh
source $BASEDIR/.env


#######################################################################################################################
# Run script archive delete partition
#######################################################################################################################
log_info "Start archive delete partition job" 
archive_delete_partition  $DB_NAME $TABLE_NAME $ARCHIVE_DB_NAME $ARCHIVE_TABLE_NAME $MASTER_DB_HOST $MASTER_DB_PORT $MASTER_DB_USER $MASTER_DB_PASS $SLAVE_DB_HOST $SLAVE_DB_PORT $SLAVE_DB_USER $SLAVE_DB_PASS $SLAVE_CONTAINER_NAME $SLAVE_CONTAINER_DATA_PATH $SLAVE_MACHINE_TEMP_FOLDER $ARCHIVE_DB_HOST $ARCHIVE_DB_PORT $ARCHIVE_DB_USER $ARCHIVE_DB_PASS $ARCHIVE_CONTAINER_NAME $ARCHIVE_CONTAINER_DATA_PATH $ARCHIVE_MACHINE_HOST $ARCHIVE_MACHINE_USER $ARCHIVE_MACHINE_PASS $ARCHIVE_MACHINE_TEMP_FOLDER $AFTER_WEEKS $BEFORE_WEEKS
log_info "End"

