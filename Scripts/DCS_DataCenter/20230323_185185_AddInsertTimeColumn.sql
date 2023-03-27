/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230323@Terry.Nguyen 
	Task:	 	Add InsertTime column for RawTrans and ProccessedTran [Redmine ID: #185185]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20230323@Terry.Nguyen: Created [Redmine ID: #185185]
	Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`RawTransaction` 
ADD COLUMN `InsertTime` TIMESTAMP(4) NULL AFTER `TransID`;


ALTER TABLE `DCS_DataCenter`.`ProcessedTransaction` 
ADD COLUMN `InsertTime` TIMESTAMP(4) NULL AFTER `TransID`;