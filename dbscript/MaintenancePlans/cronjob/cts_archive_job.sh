#/bin/bash
CTS_DIR=/var/cts

########## INIT ERROR_CODE
ERROR_CODE=0
########## RUN init function
bash ${CTS_DIR}/archive/archive_init_run.sh

echo "INIT STATUS ERROR: ${ERROR_CODE}"
if [ "$ERROR_CODE" = "0" ]
then
	###############################
	bash ${CTS_DIR}/archive/archive_process_run.sh "Transaction07"

	###############################################
	bash ${CTS_DIR}/archive/archive_process_run.sh "ProcessedTransaction"
fi

