/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241203@Thomas.Nguyen
Task:	 	add tables
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241203@Thomas.Nguyen: Created [Redmine ID: #214353]
Reviewer:
*/

USE CTS_DataCenter;

/*New tables*/
CREATE TABLE DangerousAssociation
(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	CustID BIGINT UNSIGNED NOT NULL,
	IsDisabled BIT(1) DEFAULT 0,
	InsertedTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	ArchivedDate DATETIME,
	PRIMARY KEY (ID),
	KEY IX_DangerousAssociation_CustID_IsDisabled (CustID, IsDisabled)
);

CREATE TABLE DangerousAssociation_DevicePool
(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	CTSCustID BIGINT UNSIGNED NOT NULL,
    DCSDeviceID BIGINT,
	InsertedTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	PRIMARY KEY (ID),
	KEY IX_DgrAssociation_DevicePool_CTSCustID_DCSDeviceID (CTSCustID, DCSDeviceID)
);

/*Add setting column*/
ALTER TABLE CTS_DataCenter.CustomerCategorySettings 
ADD COLUMN FlowNormalDgrAssociation	 	TINYINT NOT NULL DEFAULT 0 COMMENT 'Flow Normal Dangerous Association - Check category to scan';

UPDATE CTS_DataCenter.CustomerCategorySettings AS s
SET 	s.FlowNormalDgrAssociation = CASE WHEN s.CategoryID IN (40100,40400,40500,40600) THEN 1 ELSE 0 END;
    
/*Init params*/
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(183,'NormalDangerousAssociationCheck_LastCTSAssDevID','NormalDangerousAssociationCheck_LastCTSAssDevID','BIGINT UNSIGNED','0');
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(184,'NormalDangerousAssociationScan_LastScannedID','NormalDangerousAssociationScan_LastScannedID','BIGINT','0');

/*Update param*/
SELECT MAX(CTSAssDevID)
INTO @lv_MaxCTSAssDevID
FROM CTS_DataCenter.AssociationByDevice;

UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = @lv_MaxCTSAssDevID
WHERE ParameterID = 183;