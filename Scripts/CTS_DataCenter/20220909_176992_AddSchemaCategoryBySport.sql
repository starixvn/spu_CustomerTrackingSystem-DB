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
	,	KEY IX_CTSCustomerClassification_BySport_CustSportGroup(CTSCustID)
	,	KEY IX_CTSCustomerClassification_BySport_CategoryID_CustID(CategoryID, CustID, LastScannedDate)
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
	,KEY IX_ProbationAccountMonitor_BySport_CreatedDate(CreatedDate)
	,KEY IX_ProbationAccountMonitor_BySport_TargetCategoryID(TargetCategoryID)
	,KEY IX_ProbationAccountMonitor_BySport_LastScannedDate(LastScannedDate)
	,KEY IX_ProbationAccountMonitor_BySport_CTSCustID(CTSCustID)
	) ENGINE = InnoDB;
    

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('113', 'DailyScan_Normal_BySport_BatchSize', 'DailyScan_Normal_BySport_BatchSize', 'BIGINT', '0');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('114', 'DailyScan_Normal_BySport_LastCategoryID', 'DailyScan_Normal_BySport_LastCategoryID', 'BIGINT', '0');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('115', 'DailyScan_Normal_BySport_LastCustID', 'DailyScan_Normal_BySport_LastCustID', 'BIGINT', '0');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('116', 'DailyScan_Normal_BySport_LastSportID', 'DailyScan_Normal_BySport_LastSportID', 'SMALLINT', '0');


