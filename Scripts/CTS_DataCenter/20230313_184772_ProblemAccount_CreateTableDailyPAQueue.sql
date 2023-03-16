/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20230313@Jonas.Huynh
Task:	 	Update Job Daily Scan PA
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230313@Jonas.Huynh: Created [#184772]
Reviewer:
*/

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomerClassification_DailyPAQueue (
		ID				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
    ,	CustID			BIGINT UNSIGNED NOT NULL
    , 	CreatedTime		DATETIME NOT NULL
	, 	INDEX			IX_CTSCustomerClassification_DailyPAQueue_CreatedTime(CreatedTime)
	, 	INDEX			IX_CTSCustomerClassification_DailyPAQueue_CustID(CustID)
) ENGINE=INNODB;

DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_DailyScan_GetPA;
DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_DailyScan_GetPA_xtest;

DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_GetByCustIDsAndCategoryIDs;
DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_GetByCustIDsAndCategoryIDs_xtest;

DELETE FROM CTS_DataCenter.SystemParameter WHERE ParameterID in (88, 89);
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('88', 'DailyScan_PA_LastScannedTime', 'Last Scanned Time Daily ScanPA', 'DATETIME', '2023-03-14 21:00:00');
