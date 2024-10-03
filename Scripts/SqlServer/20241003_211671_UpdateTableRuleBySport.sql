/*
    Creator: 	20241003@Jonas.Huynh
    Task:	 	Change Betcount Rule [Redmine ID: #211671]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

SELECT *
FROM [bodb_VR2Model].[dbo].[CustomerClassification_BySport_Rule]
WHERE RuleGroupId in (301, 303, 402, 502) and SportId = 145;

UPDATE[bodb_VR2Model].[dbo].[CustomerClassification_BySport_Rule]
SET BetCount = 20
WHERE RuleGroupId in (301, 303, 402, 502) and SportId = 145;

SELECT *
FROM [bodb_VR2Model].[dbo].[CustomerClassification_BySport_Rule]
WHERE RuleGroupId in (301, 303, 402, 502) and SportId = 145;