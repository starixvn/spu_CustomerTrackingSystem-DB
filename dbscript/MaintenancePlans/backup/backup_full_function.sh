#!/bin/bash
function process_full_backup()
{
    ###### input params
    from_container=$1
    backup_path=$2
    login_backup_path=$3
    backup_dbname=$4
    login_log_path=$5
    log_dbname=$6
    run_date=$7
    zip_mode=$8
    
    ##### local variables
    BKSizeM=0

    if [ -n "$backup_path" ]
    then
        ##### log start process
        docker exec ${from_container} mysql --login-path=${login_log_path} -D${log_dbname} -e "
            INSERT INTO dba_BackupTask_Log(db_name,file_name,run_date) value ('$backup_dbname','$backup_path','$run_date');
        "

        ##### do backup process
        if [ "$zip_mode" = "0" ]
        then
            docker exec ${from_container} mysqldump --login-path=${login_backup_path} \
                    --set-gtid-purged=OFF --single-transaction --quick --routines --triggers --events ${backup_dbname} > ${backup_path}

        elif [ "$zip_mode" = "1" ]
	then
            docker exec ${from_container} mysqldump --login-path=${login_backup_path} \
                --set-gtid-purged=OFF --single-transaction --quick --routines --triggers --events ${backup_dbname} | gzip > ${backup_path}
        fi

        ##### log end process
        BKSizeM=`du -sm $backup_path | awk '{print $1}'`
        docker exec ${from_container} mysql --login-path=${login_log_path} -D${log_dbname} -e "
            update dba_BackupTask_Log set file_size_m=$BKSizeM,end_time=current_timestamp() where file_name='$backup_path';
        "
        echo "${backup_path}: SUCCESS"
        return 0
    fi

    echo "FAILED"
    return -1
}
