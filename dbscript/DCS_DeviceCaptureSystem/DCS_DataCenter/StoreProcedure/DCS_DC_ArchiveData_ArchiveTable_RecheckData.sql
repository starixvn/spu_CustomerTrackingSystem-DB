/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_ArchiveTable_RecheckData`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_ArchiveTable_RecheckData`(
)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240419@Jonathan.Doan
		Task:		Recheck Account before archive
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20240419@Jonathan.Doan: Created [Redmine ID: #203691]
		Param's Explanation (filtered by):
			CALL DCS_DC_ArchiveData_ArchiveTable_RecheckData();
	*/
    DECLARE CONST_SYSTEM_ARCHIVE_MINACCOUNTLASTLOGINTIME	INT DEFAULT 4963735;
    DECLARE lv_MinAccountLastLoginTime  	DATE;
    
    SET lv_MinAccountLastLoginTime = (SELECT DATE(VValue) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_SYSTEM_ARCHIVE_MINACCOUNTLASTLOGINTIME);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountReActived;
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceReActived;
    
    CREATE TEMPORARY TABLE Temp_AccountReActived(
			AccountID 		BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_DeviceReActived(
			DeviceID 		BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
    INSERT INTO Temp_AccountReActived(AccountID)
    SELECT aa.AccountID
	FROM DCS_DataCenter.ArchiveAccount_NotUsed AS aa
		INNER JOIN DCS_DataCenter.Account AS acc ON acc.AccountID = aa.AccountID
	WHERE acc.LastLoginTime >= lv_MinAccountLastLoginTime;
    
    INSERT INTO Temp_DeviceReActived(DeviceID)
    SELECT DISTINCT aa.DeviceID
    FROM DCS_DataCenter.ArchiveAssociation_NotUsed AS aa
		INNER JOIN Temp_AccountReActived AS tmp ON tmp.AccountID = aa.AccountID;
        
    
    DELETE aa
    FROM DCS_DataCenter.ArchiveAccount_NotUsed AS aa
		INNER JOIN Temp_AccountReActived AS tmp ON tmp.AccountID = aa.AccountID;
    
    DELETE aa
    FROM DCS_DataCenter.ArchiveAccountIP_NotUsed AS aa
		INNER JOIN Temp_AccountReActived AS tmp ON tmp.AccountID = aa.AccountID;
    
    DELETE aa
    FROM DCS_DataCenter.ArchiveAccountFingerprint_NotUsed AS aa
		INNER JOIN Temp_AccountReActived AS tmp ON tmp.AccountID = aa.AccountID;
    
    DELETE aa
    FROM DCS_DataCenter.ArchiveAccountDevice_NotUsed AS aa
		INNER JOIN Temp_AccountReActived AS tmp ON tmp.AccountID = aa.AccountID;
    
    DELETE aa
    FROM DCS_DataCenter.ArchiveAssociation_NotUsed AS aa
		INNER JOIN Temp_AccountReActived AS tmp ON tmp.AccountID = aa.AccountID;
        
    DELETE ad
    FROM DCS_DataCenter.ArchiveDevice_NotUsed AS ad
		INNER JOIN Temp_DeviceReActived AS tmp ON tmp.DeviceID = ad.DeviceID;
        
    DELETE ad
    FROM DCS_DataCenter.ArchiveDeviceCode_NotUsed AS ad
		INNER JOIN Temp_DeviceReActived AS tmp ON tmp.DeviceID = ad.DeviceID;
    
    
END$$

DELIMITER ;