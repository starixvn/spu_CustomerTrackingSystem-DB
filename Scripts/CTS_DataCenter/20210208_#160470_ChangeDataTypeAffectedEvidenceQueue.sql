/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210830@Aries.Nguyen
Task:	 	Sync insert remove affected evidence [Redmine ID: #160470]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CustEvidenceAffectedQueueInsert CHANGE Created Created DATETIME(3) DEFAULT NOW(3), ALGORITHM=COPY;
ALTER TABLE CTS_DataCenter.CustEvidenceAffectedQueueRemove CHANGE Created Created DATETIME(3) DEFAULT NOW(3), ALGORITHM=COPY;
