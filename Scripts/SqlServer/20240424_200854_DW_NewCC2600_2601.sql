/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
Creator:	20240424@Thomas.Nguyen
Task:	 	New CC 2600/2601.
Server:  	DBVR2
DBName:		bodb_VR2Model

Revisions: 
		- 20240424@Thomas.Nguyen: Created [Redmine ID: #200854]
Reviewer:
*/

USE bodb_VR2Model;

#=================================================
INSERT INTO CustomerClassification_Parameter(DataId,DataDescription,DataType,Value)
SELECT 14, 'Normal Accounts Classification - InitialGroupBetting - Service - Last Scanned CustID', 'BIGINT' , 0;

DELETE p WITH(ROWLOCK)
FROM CustomerClassification_Priority p
WHERE p.FunctionId = 8;

DROP PROCEDURE IF EXISTS `CTS_GeneralNormalClassification_TWGroupBetting_Preprocess`;

ALTER TABLE CustomerClassification_ScannedNewCust
ALTER COLUMN LastJobScannedTime DATETIME2;