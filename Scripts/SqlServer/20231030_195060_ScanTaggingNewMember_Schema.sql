/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20231030@Victoria.Le
    Task:	 	New CC 2300 - New Group Betting 
    DBName:		bodb_VR2Model
	
	Revisions: 
		- 20231030@Victoria.Le: Initial Writing [Redmine ID: #195060]

*/
USE [bodb_VR2Model]
GO

CREATE TABLE dbo.CustomerClassification_ScannedNewCust(
		CustId					INT			PRIMARY KEY
	,	TotalTicketCount		INT			DEFAULT 0
	,	GBTicketCount			INT			DEFAULT 0
	,	SportType				INT 		NULL
	,	CreatedTime 			DATETIME 	NOT NULL
	,	JobScannedType			TINYINT		DEFAULT 0 /* '0: Scanning 1: Scanned Completed - Check Rule Failed 2: Scanned Completed - Check Rule Passed' */
	,	LastJobScannedTime		DATETIME 	NULL
	,	IsServiceScanned		BIT 		DEFAULT 0
	,	LastServiceScannedTime	DATETIME 	NULL
);

CREATE NONCLUSTERED INDEX [IX_CC_ScannedNewCust_CustID_IsServiceScanned] ON [dbo].[CustomerClassification_ScannedNewCust] (CustId, IsServiceScanned);
CREATE NONCLUSTERED INDEX [IX_CC_ScannedNewCust_CustId_JobScannedType] ON [dbo].[CustomerClassification_ScannedNewCust] (CustId, JobScannedType);
CREATE NONCLUSTERED INDEX [IX_CC_ScannedNewCust_LastScannedTime_IsServiceScanned] ON [dbo].[CustomerClassification_ScannedNewCust] (JobScannedType, LastServiceScannedTime, IsServiceScanned);

