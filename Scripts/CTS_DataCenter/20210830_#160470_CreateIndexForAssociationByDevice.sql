/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20210830@Aries.Nguyen
	Task:	 	Create index [Redmine ID: #160470]
	DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.AssociationByDevice ADD INDEX IX_AssociationByDevice_CreatedTime (CreatedTime), ALGORITHM=INPLACE, LOCK=NONE;;

