/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20230228@Jonas.Huynh
Task:	 	Job Monitoring Category and Customer
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230228@Jonas.Huynh: Created [#183278]
Reviewer:
*/

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomerClassification_IncorrectCategoryMonitor (
    	CustID			BIGINT UNSIGNED NOT NULL
    , 	CategoryID		SMALLINT UNSIGNED
    , 	ScannedTime		DATETIME NOT NULL
    , 	CreatedTime		DATETIME NOT NULL
	, 	IsResolved		BOOLEAN DEFAULT FALSE
    ,	InvalidType		SMALLINT NOT NULL COMMENT '1:New Customer with null category - 2:New placebet with inactive category - 3:Customer placebet with null category' 
	, 	INDEX			IX_CTSCustomerClassification_Monitor_CustID(CustID)
    , 	INDEX			IX_CTSCustomerClassification_Monitor_ScannedTime(ScannedTime)
    , 	INDEX			IX_CTSCustomerClassification_Monitor_IsResolved(IsResolved)
) ENGINE=INNODB;


INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('130', 'MonitorRealtimeCategory_LastScannedDate', 'Mornitor customer places new bets', 'DATETIME', '2022-03-01 00:00:00');

DROP PROCEDURE IF EXISTS CTS_DC_CustInfo_Monitoring_CompareData; 
DROP PROCEDURE IF EXISTS CTS_DC_CustInfo_Monitoring_InsertMissingCust;

ALTER TABLE CTS_DataCenter.CTSCustomer_Missing RENAME COLUMN IsResync TO IsResolved; 
ALTER TABLE CTS_DataCenter.CTSCustomer_Missing RENAME COLUMN ScannedDate TO ScannedTime; 
ALTER TABLE CTS_DataCenter.CTSCustomer_Missing MODIFY COLUMN IsResolved BOOLEAN DEFAULT FALSE;
ALTER TABLE CTS_DataCenter.CTSCustomer_Missing MODIFY COLUMN ScannedTime DATETIME NOT NULL;
CREATE INDEX IX_CTSCustomer_Missing_ScannedDate ON CTSCustomer_Missing (ScannedTime);