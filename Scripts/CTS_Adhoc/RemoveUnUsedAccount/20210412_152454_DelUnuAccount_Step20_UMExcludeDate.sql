/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step20_UMExcludeData`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step20_UMExcludeData`(
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		Remove data In UM Time If ((acc.ISCTSTransformed = 1	OR acc.LastLoginTime >= '2021-01-01')
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/   
	DROP TEMPORARY TABLE IF EXISTS Temp_RemoveAccountID;
    CREATE TEMPORARY TABLE Temp_RemoveAccountID
    (
		AccountID BIGINT UNSIGNED PRIMARY KEY
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveDeviceID;
    CREATE TEMPORARY TABLE Temp_RemoveDeviceID
    (
		DeviceID BIGINT UNSIGNED NOT NULL PRIMARY KEY
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveAssociationID;
    CREATE TEMPORARY TABLE Temp_RemoveAssociationID
    (
		AssociationID BIGINT UNSIGNED NOT NULL PRIMARY KEY
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveDeviceCodeID;
    CREATE TEMPORARY TABLE Temp_RemoveDeviceCodeID
    (
		DeviceCodeID BIGINT UNSIGNED NOT NULL PRIMARY KEY
    ); 
    SELECT  '1.Get Exclude Account';  
	INSERT INTO Temp_RemoveAccountID(AccountID)
	SELECT 		delAcc.AccountID
	FROM		CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc
	INNER JOIN	DCS_DataCenter.Account AS acc ON delAcc.AccountID = acc.AccountID
	WHERE		acc.LastLoginTime >= '2021-02-01'
				OR acc.ISCTSTransformed = 1; #138s
                
    SELECT  '2.Remove Account';           
	DELETE 	delAcc
    FROM 	CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc
		INNER JOIN Temp_RemoveAccountID AS tmp ON tmp.AccountID = delAcc.AccountID; #3s
    
    SELECT  '3.Get Exclude Device By exclude Account';     
	INSERT IGNORE INTO Temp_RemoveDeviceID(DeviceID)
    SELECT DISTINCT ass.DeviceID
    FROM Temp_RemoveAccountID AS tmp
		INNER JOIN CTS_Adhoc.CS152454_DelUnuAccount_Association AS ass ON tmp.AccountID = ass.AccountID; #12s
    
    SELECT  '4.Get Exclude Device By Account not in (Delete Account)';   
    INSERT IGNORE INTO Temp_RemoveDeviceID(DeviceID)
    SELECT 	delDev.DeviceID
	FROM	CTS_Adhoc.CS152454_DelUnuAccount_Device AS delDev
		INNER JOIN	DCS_DataCenter.Association AS ass ON delDev.DeviceID = ass.DeviceID
		LEFT JOIN	CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc ON delAcc.AccountID = ass.AccountID
	WHERE	delAcc.AccountID IS NULL; #6s
	
    SELECT  '5.Remove Devive'; 
    DELETE 	delDev
    FROM 	CTS_Adhoc.CS152454_DelUnuAccount_Device AS delDev
		INNER JOIN Temp_RemoveDeviceID AS tmp ON tmp.DeviceID = delDev.DeviceID; #0.1 =1K
    
	SELECT  '6.Remove DeviveCode'; 
	DELETE 	delDec
    FROM 	CTS_Adhoc.CS152454_DelUnuAccount_DeviceCode AS delDec
		INNER JOIN Temp_RemoveDeviceID AS tmp ON tmp.DeviceID = delDec.DeviceID; #37s 1K
	
    SELECT  '7.Remove DeviceFingerprint'; 
    DELETE 	delDef
    FROM 	CTS_Adhoc.CS152454_DelUnuAccount_DeviceFingerprint AS delDef
		INNER JOIN Temp_RemoveDeviceID AS tmp ON tmp.DeviceID = delDef.DeviceID; #25s 1.5K    
	
END