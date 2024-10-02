/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20241001@Jonathan.Doan
	Task:	 	Delete Param unused [Redmine ID: #211161]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20241001@Jonathan.Doan: Created [Redmine ID: #211161]
	Reviewer:
*/

USE DCS_DataTrace;

DELETE FROM `DCS_DataTrace`.`SystemSetting`
WHERE ID IN (6, 100, 101);

DROP PROCEDURE IF EXISTS `Adhoc_DCS_DT_Initial_LoginTransactionSummaryByDevice_Insert`;