/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250416@Thomas.Nguyen
Task:	 	new tables and system params
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250416@Thomas.Nguyen: Created [Redmine ID: #223443]
Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE CTSCustomerLatencyQueue
(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	CustID BIGINT UNSIGNED NOT NULL,
    LatencyType TINYINT NULL COMMENT '2: New Customer - Missing Customer, 3: New Customer - Missing CustInfo, Reactivated Customer - Missing',
	InsertedTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	PRIMARY KEY (ID),
	KEY IX_CTSCustomerLatencyQueue_CustID (CustID)
);

CREATE TABLE CTSCustomerLatencyQueue_Archive
(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	CustID BIGINT UNSIGNED NOT NULL,
    LatencyType TINYINT NULL COMMENT '2: New Customer - Missing Customer, 3: New Customer - Missing CustInfo, Reactivated Customer - Missing',
	InsertedTime DATETIME(3),
	ArchivedDate DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	PRIMARY KEY (ID),
	KEY IX_CTSCustomerLatencyQueue_CustID (CustID)
);

SELECT ParameterValue
INTO @lv_MonitorInsertCust_LastScannedCustID
FROM SystemParameter
WHERE ParameterID = 131;

SELECT ParameterValue
INTO @lv_JobMonitoring_ReactivatedCustLastScannedTime
FROM SystemParameter
WHERE ParameterID = 185;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(188,'CustomerLatencyScan_LastScannedCustID','CustomerLatencyScan_LastScannedCustID','BIGINT',@lv_MonitorInsertCust_LastScannedCustID);
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(189,'ReactivatedCustLatencyScan_LastScannedTime','ReactivatedCustLatencyScan_LastScannedTime','DATETIME',@lv_JobMonitoring_ReactivatedCustLastScannedTime);

INSERT INTO StaticList (ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, ItemParentItemID, ItemDefaultValue, ItemValue, PriorityOrder, Status, Description, CreatedDate)
VALUES (20,300,'Job Monitoring IssueType','Job Monitoring IssueType','Customer Latency Scan - Excessive Pool','Customer Latency Scan - Excessive Pool',NULL,NULL,NULL,NULL,1,NULL,NOW());