/*<info serverAlias="DBVR2-bodb_VR2Model" executers="DBCTS-WASAVerse" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240515@Thomas.Nguyen
    Task:	 	Special Lic Sub CC [Redmine ID: #226847]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

ALTER TABLE CustomerClassification
ADD ScanSpecialLicSubType TINYINT DEFAULT 0;

INSERT INTO dbo.CustomerClassification_Priority(GroupId, GroupName, FunctionId, FunctionName, Priority) 
VALUES 
(1, 'ByFlow', 10, 'Scan Special Lic Sub CC', 5);