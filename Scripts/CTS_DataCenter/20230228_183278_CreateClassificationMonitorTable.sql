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
		ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    ,	CustID			BIGINT UNSIGNED NOT NULL
    , 	CategoryID		SMALLINT UNSIGNED
    , 	CreatedDate		DATETIME NOT NULL
	, 	IsResolved		BOOLEAN DEFAULT FALSE
    ,	InvalidType		SMALLINT NOT NULL COMMENT '1:New Customer with null category - 2:New placebet with inactive category'
    ,	INDEX			IX_CTSCustomerClassification_Monitor_CustIDCreatedDate(CustID, CreatedDate)
	, 	INDEX			IX_CTSCustomerClassification_Monitor_CreatedDate(CreatedDate)
    , 	INDEX			IX_CTSCustomerClassification_Monitor_IsResolved(IsResolved)
) ENGINE=INNODB AUTO_INCREMENT=1;


INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('130', 'MonitorRealtimeCategory_LastScannedDate', 'Mornitor customer places new bets', 'DATETIME', '2022-03-01 00:00:00');
