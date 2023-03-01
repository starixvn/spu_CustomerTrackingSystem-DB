/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230225@Jonas.Huynh
    Task:	 	Job monitor [Redmine ID: #183278]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO


CREATE TABLE [dbo].[CustomerClassification_Monitor_Realtime](
	[CustId] [int]				NOT NULL,
	[CreatedDate] [Datetime]	NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_Monitor_Realtime_CreatedDate] ON [dbo].[CustomerClassification_Monitor_Realtime]
(
	[CreatedDate] ASC
)

GO


GRANT SELECT ON [dbo].[CustomerClassification_Monitor_Realtime] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_Monitor_Realtime] TO [bodbSPUNet]
GO