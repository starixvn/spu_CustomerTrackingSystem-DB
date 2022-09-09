/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20220830@Harvey.Nguyen
	Task:	 	Update sysparam [Redmine ID: 176992] 	
	DBName:		CTS_DataCenter
*/
DROP TABLE IF EXISTS CTSCustomerClassification_BySport;
CREATE TABLE CTSCustomerClassification_BySport (
		CustID BIGINT 		UNSIGNED NOT NULL
	,	CTSCustID BIGINT UNSIGNED DEFAULT NULL
	,	SportID SMALLINT UNSIGNED NOT NULL
	,	CategoryID SMALLINT UNSIGNED NOT NULL
	,	Remark VARCHAR(500) DEFAULT NULL
	,	CreatedDate DATETIME DEFAULT NULL
	,	CreatedBy INT DEFAULT NULL
	,	LastModifiedDate DATETIME DEFAULT NULL
	,	LastModifiedBy INT UNSIGNED DEFAULT NULL
	,	LastScannedDate DATE DEFAULT NULL
	,	PRIMARY KEY (CustID,SportID)
	,	KEY IX_CTSCustomerClassification_BySport_CustSportGroup(CTSCustID, SportID, LastModifiedDate)
	,	KEY IX_CTSCustomerClassification_BySport_SportID_CreatedDate(SportID, CreatedDate)
	,	KEY IX_CTSCustomerClassification_BySport_CategoryID_CustID(CategoryID, CustID, LastScannedDate)
	) ENGINE = InnoDB;

DROP TABLE IF EXISTS CTSCustomerClassification_BySport_History;
CREATE TABLE CTSCustomerClassification_BySport_History (
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CustID 				BIGINT UNSIGNED DEFAULT NULL
	,	CTSCustID 			BIGINT UNSIGNED DEFAULT NULL
	,	SportID 			SMALLINT UNSIGNED DEFAULT NULL
	,	CategoryID 			SMALLINT UNSIGNED DEFAULT NULL
	,	TurnoverRM 			DECIMAL(20, 4) DEFAULT NULL
	,	WinlossRM 			DECIMAL(20, 4) DEFAULT NULL
	,	BetCount 			BIGINT DEFAULT NULL
	,	ActiveDays 			INT DEFAULT NULL
	,	TargetCC 			SMALLINT DEFAULT NULL
	,	FromCategoryID 		SMALLINT UNSIGNED DEFAULT NULL
	,	ActionType 			TINYINT DEFAULT NULL
	,	LastModifiedDate	DATETIME DEFAULT NULL
	,	LastModifiedBy 		INT UNSIGNED DEFAULT NULL
	,	InsertDate 			DATETIME DEFAULT NULL
	,	PRIMARY KEY (ID)
	,	KEY IX_CTSCustomerClassification_BySport_History_InsertDate(InsertDate)
	,	KEY IX_CTSCustomerClassification_BySport_History_CTSCustID(CTSCustID)
	,	KEY IX_CTSCustomerClassification_BySport_History_CustID_Infor(CustID, SportID, LastModifiedDate)
	) 	ENGINE = InnoDB;
    

DROP TABLE IF EXISTS CTSCustomerClassification_BySport_Log;
CREATE TABLE CTSCustomerClassification_BySport_Log (
	ID					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,CustID				BIGINT UNSIGNED DEFAULT NULL
	,CTSCustID			BIGINT UNSIGNED DEFAULT NULL
	,SportID			SMALLINT UNSIGNED DEFAULT NULL
	,CategoryID			SMALLINT DEFAULT NULL
	,TurnoverRM			DECIMAL(20, 4) DEFAULT NULL
	,WinlossRM			DECIMAL(20, 4) DEFAULT NULL
	,BetCount			BIGINT DEFAULT NULL
	,ActiveDays			INT DEFAULT NULL
	,TargetCC 			SMALLINT DEFAULT NULL
	,FromCategoryID 	SMALLINT UNSIGNED DEFAULT NULL
	,IsDataChanged		BOOLEAN DEFAULT FALSE
	,ActionType			TINYINT DEFAULT NULL
	,LastModifiedDate	DATETIME DEFAULT NULL
	,LastModifiedBy		INT UNSIGNED DEFAULT NULL
	,InsertDate			DATETIME NOT NULL
	,PRIMARY KEY (ID, InsertDate)
	,KEY IX_CTSCustomerClassification_BySport_Log_CustID(CustID)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS ProbationAccountMonitor_BySport;
CREATE TABLE ProbationAccountMonitor_BySport (
	CTSCustID 			BIGINT UNSIGNED NOT NULL
	,CustID 			INT UNSIGNED NOT NULL
	,SportID 			SMALLINT NOT NULL
	,TargetCategoryID 	SMALLINT DEFAULT NULL
	,FirstMargin 		DECIMAL(20, 4) DEFAULT NULL
	,CreatedBy 			INT NOT NULL
	,CreatedDate 		DATETIME NOT NULL
	,CreatedTime 		DATETIME NOT NULL
	,LastScannedDate 	DATE DEFAULT NULL
	,PRIMARY KEY (CustID, SportID)
	,KEY IX_ProbationAccountMonitor_BySport_CustID(CustID)
	,KEY IX_ProbationAccountMonitor_BySport_CreatedDate(CreatedDate)
	,KEY IX_ProbationAccountMonitor_BySport_TargetCategoryID(TargetCategoryID)
	,KEY IX_ProbationAccountMonitor_BySport_LastScannedDate(LastScannedDate)
	,KEY IX_ProbationAccountMonitor_BySport_CTSCustID(CTSCustID)
	) ENGINE = InnoDB;
    

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('113', 'DailyScan_Normal_BySport_BatchSize', 'DailyScan_Normal_BySport_BatchSize', 'BIGINT', '0');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('114', 'DailyScan_Normal_BySport_LastCategoryID', 'DailyScan_Normal_BySport_LastCategoryID', 'BIGINT', '0');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('115', 'DailyScan_Normal_BySport_LastCustID', 'DailyScan_Normal_BySport_LastCustID', 'BIGINT', '0');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('116', 'DailyScan_Normal_BySport_LastSportID', 'DailyScan_Normal_BySport_LastSportID', 'SMALLINT', '0');


