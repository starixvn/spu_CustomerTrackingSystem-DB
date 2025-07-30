/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
Creator:	20250725@Winfred.Pham
Task:	 	
Server:  	Master
DBName:		CTS_Archive

Revisions: 
		- 20250725@Winfred.Pham: Created [Redmine ID: #219679]
Reviewer:
*/

USE CTS_Archive;

#================================================================================
DROP TABLE IF EXISTS CTSCustomerClassificationAgency_History_Archive;
CREATE TABLE CTSCustomerClassificationAgency_History_Archive(
		ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	HistoryID BIGINT UNSIGNED NOT NULL
	,	CustID BIGINT UNSIGNED
	,	CTSCustID BIGINT UNSIGNED
	,	RoleID TINYINT
	,	ParentID INT UNSIGNED
	,	CategoryID INT
	,	OldCategoryID INT UNSIGNED
	,	DWCategoryID INT UNSIGNED
	,	TargetCC INT
	,	SourceTypeID SMALLINT UNSIGNED
	,	IsDataChanged TINYINT(1)
	,	ActionType TINYINT
	,	IsAuto TINYINT(1)
	,	LastModifiedDate DATETIME 
	,	LastModifiedBy INT UNSIGNED
	,	InsertDate DATETIME
	,	TargetDangerLevel1 SMALLINT
	,	Remark VARCHAR(500) 
	,	IsMarkedDirectly TINYINT(1)
	,	IsFromTW TINYINT(1)
	,	IsFromCTS TINYINT(1)
	,	IsFromAI TINYINT(1)
	,	TurnoverRM DECIMAL(20,4) 
	,	WinlossRM DECIMAL(20,4)
	,	BetCount BIGINT
	,	LastXDaysTurnoverRM DECIMAL(20,4)
	,	LastXDaysWinlossRM DECIMAL(20,4)
	,	LastXDaysBetCount BIGINT
	,	LastYDaysTurnoverRM DECIMAL(20,4) 
	,	LastYDaysWinlossRM DECIMAL(20,4)
	,	LastYDaysBetCount BIGINT 
	,	PerformanceTime DATETIME 
	,	RobotCounter SMALLINT
	,	CustomerCategorySettingsAgency TINYINT 
	,	SystemRemark VARCHAR(255)
	,	PRIMARY KEY(ID,InsertDate) 
	,	KEY IX_CTSCustomerClassificationAgency_History_Archive_CustID(CustID) 
) ENGINE=InnoDB;
