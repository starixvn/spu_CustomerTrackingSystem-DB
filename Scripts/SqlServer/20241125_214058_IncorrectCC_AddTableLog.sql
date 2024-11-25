/*<info serverAlias="DBVR2-bodb_VR2Model" executers="DBCTS-WASAVerse" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20241125@Jonas.Huynh
    Task:	 	Incorrect Customer Classification [Redmine ID: #214058]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- #1. ADD TABLE CustomerClassification_DataTrace
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_DataTrace]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_DataTrace]
CREATE TABLE [dbo].[CustomerClassification_DataTrace](
		ID					BIGINT NOT NULL,
		[RowVersion]		BIGINT NOT NULL,
		LastScannedRowConv	BIGINT,
		NextScannedRowConv	BIGINT,
		IsProceeded			TINYINT DEFAULT(0),
		CustId				INT,
		[CurrentCategoryId] INT,
		CategoryId			INT,
		CategoryGroupId		INT,
		CreatedTime			DATETIME,
		TurnoverRM			DECIMAL(19, 4),
		WinlossRM			DECIMAL(19, 4),
		BetCount			BIGINT,
		ActiveDays			INT,
		PerformanceTime		DATETIME,
		ScanTaggingType		TINYINT DEFAULT(0),
		ScanTaggingTWType	TINYINT DEFAULT(0)
) ON [PRIMARY]

CREATE CLUSTERED INDEX IX_CustomerClassification_DataTrace_ID ON [CustomerClassification_DataTrace](
	ID ASC
);

CREATE NONCLUSTERED INDEX IX_CustomerClassification_DataTrace_RowVersionConV ON [CustomerClassification_DataTrace](
	LastScannedRowConv ASC,
	NextScannedRowConv ASC,
	IsProceeded ASC
);

CREATE NONCLUSTERED INDEX IX_CustomerClassification_DataTrace_CustId ON [CustomerClassification_DataTrace](
	CustId ASC,
	IsProceeded ASC
);

GO	


GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_DataTrace] TO [wsv_cts]
GO