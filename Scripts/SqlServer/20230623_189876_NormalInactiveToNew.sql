/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230623@Jonas.Huynh
    Task:	 	Realtime Renovation [Redmine ID: #189876]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

CREATE TABLE [dbo].[CustomerClassification_ResetBalance](
	CustId		 INT PRIMARY KEY,
	ResetDate	 DATE NOT NULL,	 
	CreatedTime	 DATETIME NOT NULL
)

GRANT SELECT ON [dbo].[CustomerClassification_ResetBalance] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_ResetBalance] TO [bodbSPUNet]
GO