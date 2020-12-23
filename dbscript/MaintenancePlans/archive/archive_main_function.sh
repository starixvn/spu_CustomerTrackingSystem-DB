#/bin/bash
#####################################
#slave_container=$1
#login_path=$2
#slave_dbname=$3
#archive_mode=$4
#log_dbname=$5
#####################################
function get_archive_info_to_process()
{
        #### input parrams
        from_container=$1
            login_path=$2
        source_dbname=$3
        archive_mode=$4
        log_dbname=$5

        ##### local variables
        info_command="select lg.archive_info->'$.week', lg.status, lg.row_id, pt.table_rows,  pt.table_sizeM, wk.week_next \
                from dba_ArchiveTask_Log lg, \
                lateral ( \
                    select pa.table_rows, pa.data_length/1024/1024 as table_sizeM \
                    from INFORMATION_SCHEMA.PARTITIONS pa \
                    where pa.table_schema=lg.db_name and pa.table_name=lg.obj_name and LOCATE(lg.archive_info->'$.week', pa.partition_name) > 0 \
                ) pt, \
                lateral (
                    select yearweek(date_add(CAST(STR_TO_DATE(CONCAT(lg.archive_info->'$.week','Sunday'), '%X%V %W') AS DATE), interval 1 week)) as week_next
                ) wk \
                where lg.db_name='${source_dbname}' and lg.obj_name='${archive_mode}' and lg.status='NEW' limit 1;"

        archive_info=$(docker exec ${from_container} mysql --login-path=${login_path} -D${log_dbname} -sN -e "${info_command}")

        # Set data
        partition_week=$(echo $archive_info | awk '{print $1}')
        archive_status=$(echo $archive_info | awk '{print $2}')
        archive_id=$(echo $archive_info | awk '{print $3}')
        table_rows=$(echo $archive_info | awk '{print $4}')
        table_sizeM=$(echo $archive_info | awk '{print $5}')
        week_next=$(echo $archive_info | awk '{print $6}')

        echo $partition_week $archive_status $archive_id $table_rows $table_sizeM $week_next
        return 0
}

################################################
#from_container=$1
#login_path=$2
#target_dbname=$3
#target_table_name=$4
#partition_week=
###############################################
function prepare_partition_file_from_archive()
{
        ##### input parrams
        from_container=$1
        login_path=$2
        target_dbname=$3
        target_table_name=$4
        partition_week=$5
        partition_week_next=$6

            ##### local variables
        partition_name="pw${partition_week}"
        partition_archive="${target_table_name}#${PARTITION_PREFIX}#${partition_name}"

        partition_command="ALTER TABLE ${target_table_name} \
                                reorganize partition pw999999 INTO ( \
                                        partition ${partition_name} VALUES LESS THAN (${partition_week_next}), \
                                        partition pw999999 VALUES LESS THAN (MAXVALUE) \
                                ); \
                                ALTER TABLE ${target_table_name} DISCARD PARTITION ${partition_name} TABLESPACE;
                        "
        #### add new one
        if [ -n "$partition_week" ]
        then
                docker exec ${from_container} mysql --login-path=${login_path} -D${target_dbname} -e "$partition_command"

                echo "${target_dbname}.${target_table_name} partition(${partition_name})-> SUCCESS"
                return 0
        fi

        echo "FAILED"
        return -1
}

#from_container=$1
#source_dbname=$2
#source_table_name=$3
#partition_week=$4
#login_path=$5
#target_host=$6
#remote_user=$7
#target_datadir=$8
#target_dbname=$9
#target_table_name=${10}
###############################################
function export_data_file_from_slave()
{
        #### input parrams
        from_container=$1
        source_dbname=$2
        source_table_name=$3
        partition_week=$4
        login_path=$5
        target_host=$6
        remote_user=$7
        target_datadir=$8
        target_dbname=$9
        target_table_name=${10}

        ##### local variables
        partition_name="pw${partition_week}"
        partition_file="${source_table_name}#${PARTITION_PREFIX}#${partition_name}"
        partition_to_copy="${partition_file[@]//"#"/"'#'"}"
        partition_archive="${target_table_name}#${PARTITION_PREFIX}#${partition_name}"
        partition_to_archive="${partition_archive[@]//"#"/"'#'"}"

        export_command="
                FLUSH TABLE ${source_table_name} FOR EXPORT; \
                system scp -i ${SSH_KEY_FILE} /var/lib/mysql/${source_dbname}/${partition_to_copy}.cfg ${remote_user}@${target_host}:/${target_datadir}/${target_dbname}/${partition_to_archive}.cfg; \
                UNLOCK TABLES;
        "

        if [ -n $partition_week ]
        then
            ######### copy cfg file
            docker exec ${from_container} mysql --login-path=${login_path} -D${source_dbname} -e "$export_command"
            ######### copy ibd data file
            docker exec ${from_container} scp -i ${SSH_KEY_FILE} /var/lib/mysql/${source_dbname}/${partition_file}.ibd \
                    ${remote_user}@${target_host}:/${target_datadir}/${target_dbname}/${partition_archive}.ibd

            echo "$partition_file to ${partition_archive} -> SUCCESS"
            return 0
        fi

        echo "FAILED"
        return -1
}

################################################
#archive_container=$1
#archive_host=$2
#archive_dbname=$3
#archive_path=$4
#partition_file="$5"
#partition_archive="$6"
#slave_container=$7
#archive_host=$8
#archive_user=$9
###############################################
function load_partition_file_from_archive()
{
        ##### input parrams
        from_container=$1
        target_container=$2
        target_host=$3
        remote_user=$4
        target_dbname="$5"
        target_table_name="$6"
        partition_week="$7"

        ##### local variables
        partition_name="pw${partition_week}"
        partition_archive="${target_table_name}#${PARTITION_PREFIX}#${partition_name}"
        partition_archive_to_load="${partition_archive[@]//"#"/"'#'"}"

        if [ -n "$partition_archive" -a "$partition_archive" != "FAILED" ]
        then
                docker exec ${from_container} ssh -i ${SSH_KEY_FILE} ${remote_user}@${target_host} "
                    docker exec ${target_container} chmod 660 /var/lib/mysql/${target_dbname}/${partition_archive_to_load}.ibd;\
                    docker exec ${target_container} chmod 660 /var/lib/mysql/${target_dbname}/${partition_archive_to_load}.cfg;\
                    docker exec ${target_container} chown mysql.mysql /var/lib/mysql/${target_dbname}/${partition_archive_to_load}.ibd;\
                    docker exec ${target_container} chown mysql.mysql /var/lib/mysql/${target_dbname}/${partition_archive_to_load}.cfg
                "

                echo "${target_dbname}.${partition_archive} -> SUCCESS"
                return 0
        fi

        echo "FAILED"
        return -1
}

################################################
#slave_container=$1
#archive_container=$2
#login_path=$3
#archive_dbname=$4
#archive_table_name=$5
#partition_week=$6
###############################################
function import_partition_file_from_archive()
{
        ##### input parrams
        from_container=$1
        login_path=$2
        target_dbname=$3
        target_table_name=$4
        partition_week=$5

        ##### local variables
        partition_name="pw${partition_week}"
        import_command="ALTER TABLE ${target_table_name} IMPORT PARTITION ${partition_name} TABLESPACE;"

        ##### remote execution
        if [ -n "$partition_week" ]
        then
                docker exec ${from_container} mysql --login-path=${login_path} -D${target_dbname} -e "$import_command"

                echo "${target_dbname}.${target_table_name} partition(${partition_name}) -> SUCCESS"
                return 0
        fi

        return "FAILED"
        return -1
}

################################################
#slave_container=$1
#login_path=$2
#master_dbname=$3
#master_table_name=$4
#partition_week="$5"
################################################
function delete_partition_file_from_master()
{
            ##### input parrams
            from_container=$1
            login_path=$2
            source_dbname=$3
            source_table_name=$4
            partition_week="$5"

            ##### local variables
            partition_name="pw${partition_week}"

            ##### remote execution
            if [ -n $partition_week ]
            then
                        drop_command="ALTER TABLE ${source_table_name} DROP PARTITION ${partition_name};"
                        docker exec ${from_container} mysql --login-path=${login_path} -D${source_dbname} -e "$drop_command"

                        echo "${source_dbname}.${source_table_name} partition(${partition_name}) -> SUCCESS"
                        return 0
            fi

            echo "FAILED"
        return -1
}