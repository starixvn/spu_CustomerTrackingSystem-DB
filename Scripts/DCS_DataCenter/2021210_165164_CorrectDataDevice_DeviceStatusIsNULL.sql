/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211130@Casey.Huynh
Task:	 	Correct Device Data
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20211130@Casey.Huynh: Created [Redmine ID: #165164]
Reviewer:
*/
USE DCS_DataCenter;

/***ISSUE01: DeviceID = 0 ************************************************
1. STOP SERVICE
2. Get remain data
3. Run Delete Script
4. Rescan CC

*************************************************************************/
/***********STEP 2.1: Get remain data***************************/
USE CTS_Adhoc;
CALL AH_CheckConsistent_DCS_DeviceCode(10000);
CALL AH_CheckConsistent_DCS_DeviceFingerprint(10000);
CALL AH_CheckConsistent_DCS_Association(10000);
CALL AH_CheckConsistent_CTS_AssociationByDevice(10000);

#====STEP 2.2: GET Customer Classification ========================================================
DROP TABLE IF EXISTS CTS_Adhoc.AH_CheckConsistent_TaggingByAssociationWithPA;
CREATE TABLE CTS_Adhoc.AH_CheckConsistent_TaggingByAssociationWithPA(
		CustID INT UNSIGNED PRIMARY KEY
    , 	CategoryID INT
    ,	PRIMARY KEY (CustID,CategoryID)
);

INSERT INTO CTS_Adhoc.AH_CheckConsistent_TaggingByAssociationWithPA(CustID, CategoryID)
SELECT	DISTINCT cls.CustID
	,	cls.CategoryID
FROM AH_CheckConsistent_AssociationByDevice_MissDevice dv 
	INNER JOIN CTS_DataCenter.CTSCustomerClassification cls ON dv.CTSCustID = cls.CTSCustID
WHERE cls.CategoryID IN (231,232,233,221,222,223,211,212,213,251,252,253,261,262,263,271,272,273);

/***********STEP 2.3: Check Data Missing Device***************************/
SELECT 'AH_CheckConsistent_Association_MissDevice' AS TableName, COUNT(1), MAX(DeviceID) FROM AH_CheckConsistent_Association_MissDevice;
SELECT 'AH_CheckConsistent_AssociationByDevice_MissDevice' AS TableName, COUNT(1), MAX(DCSDeviceID) FROM AH_CheckConsistent_AssociationByDevice_MissDevice;
SELECT 'AH_CheckConsistent_Device' AS TableName, COUNT(1), MAX(DeviceID) FROM AH_CheckConsistent_Device;
SELECT 'AH_CheckConsistent_DeviceCode' AS TableName, COUNT(1), MAX(DeviceID) FROM AH_CheckConsistent_DeviceCode;
SELECT 'AH_CheckConsistent_DeviceFingerprint' AS TableName, COUNT(1), MAX(DeviceID) FROM AH_CheckConsistent_DeviceFingerprint;

/***********STEP 3: Run Delete Script***************************/
#============DCS_DataCenter===================== 
USE DCS_DataCenter;
DELETE del
FROM DCS_DataCenter.DeviceFingerprint AS del
	INNER JOIN CTS_Adhoc.AH_CheckConsistent_DeviceFingerprint AS dv ON del.DeviceFingerprintID = dv.DeviceFingerprintID;
    
DELETE del
FROM DCS_DataCenter.DCS_DeviceCode AS del
	INNER JOIN CTS_Adhoc.AH_CheckConsistent_DeviceCode AS dv ON del.DeviceCodeID = dv.DeviceCodeID;
    
DELETE del
FROM DCS_DataCenter.Association AS del
	INNER JOIN CTS_Adhoc.AH_CheckConsistent_DeviceCode AS dv ON del.AssociationID = dv.AssociationID;

#============CTS_DataCenter===================== 
USE CTS_DataCenter;
DELETE del
FROM CTS_DataCenter.AssociationByDevice AS del
	INNER JOIN CTS_Adhoc.AH_CheckConsistent_CTS_AssociationByDevice AS dv ON del.DeviceID = dv.DeviceID;
    

