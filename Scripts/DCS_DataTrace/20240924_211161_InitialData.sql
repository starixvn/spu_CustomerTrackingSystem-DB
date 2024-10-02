/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20240924@Jonathan.Doan
	Task:	 	Run SP to initial data by device [Redmine ID: #211161]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20240924@Jonathan.Doan: Created [Redmine ID: #211161]
	Reviewer:
*/

USE DCS_DataTrace;

CALL DCS_DataTrace.Adhoc_DCS_DT_Initial_LoginTransactionSummaryByDevice_Insert(1000);