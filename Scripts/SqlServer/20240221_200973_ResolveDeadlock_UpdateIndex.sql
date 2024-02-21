/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240221@Jonas.Huynh
    Task:	 	Enhance Blocking [Redmine ID: #200973]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_CustIdSportId] ON [dbo].[CustomerClassification_BySport]
(
	[CustId] ASC,
	[SportId]
);
GO

DROP INDEX [IX_CustomerClassification_Id] ON [dbo].[CustomerClassification];
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_CustomerClassification_Id] ON [dbo].[CustomerClassification]
(
	[ID] ASC
);
GO
