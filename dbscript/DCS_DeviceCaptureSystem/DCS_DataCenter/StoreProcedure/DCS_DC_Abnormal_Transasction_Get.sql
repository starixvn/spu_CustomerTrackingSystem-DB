/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Abnormal_Transasction_Get`(
		IN ip_Size INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20230316@Jonathan.Doan
	Task : Support return new device login for Alpha
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20230316@Jonathan.Doan: Get Data [Redmine ID: 185185]
		
	Param's Explanation (filtered by):

	Example:
		- CALL DCS_DataCenter.DCS_DC_Abnormal_Transasction_Get(10);
	*/
    DECLARE lv_SystemSettingVGroup VARCHAR(128) DEFAULT 'DCS_AbnormalTransaction_Processed';
    DECLARE lv_SystemSettingVName VARCHAR(128) DEFAULT 'MaxID';
    DECLARE lv_SystemSettingVValue BIGINT UNSIGNED;
    DECLARE lv_MinID BIGINT UNSIGNED;
    DECLARE lv_MaxID BIGINT UNSIGNED;
    
    SET lv_SystemSettingVValue = IFNULL((SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE VGroup=lv_SystemSettingVGroup AND VName=lv_SystemSettingVName), 0);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewAccountDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_NewAccountDevice_Validated;
    DROP TEMPORARY TABLE IF EXISTS Temp_Account_Count_Device_History;
    DROP TEMPORARY TABLE IF EXISTS Temp_Account_MinID;
    
    CREATE TEMPORARY TABLE Temp_NewAccountDevice(
			AssociationID BIGINT UNSIGNED PRIMARY KEY
        ,	AccountID BIGINT UNSIGNED
        
        ,	INDEX 	IX_Temp_NewAccountDevice_AccountID(AccountID)
    );
    
    CREATE TEMPORARY TABLE Temp_NewAccountDevice_Validated(
			AssociationID 	BIGINT UNSIGNED PRIMARY KEY
        ,	AccountID 		BIGINT UNSIGNED
    );
    
    CREATE TEMPORARY TABLE Temp_Account_Count_Device_History(
			AccountID 		BIGINT UNSIGNED PRIMARY KEY
        ,	Count 			INT UNSIGNED DEFAULT 0
    );
    
    CREATE TEMPORARY TABLE Temp_Account_MinID(
			MinID 			BIGINT UNSIGNED PRIMARY KEY
        ,	AccountID 		BIGINT UNSIGNED
    );
    
    INSERT INTO Temp_NewAccountDevice(AssociationID, AccountID)
    SELECT 	AssociationID
		,	AccountID
	FROM DCS_DataCenter.NewAccountDevice PARTITION(p10000000)
	WHERE AssociationID > lv_SystemSettingVValue
		AND status = 0
    ORDER BY AssociationID
    LIMIT ip_Size;
    
    SELECT	IFNULL(MIN(AssociationID),0)
		,	IFNULL(MAX(AssociationID),0)
    INTO 	lv_MinID
		,	lv_MaxID
	FROM Temp_NewAccountDevice;
    
    INSERT INTO Temp_Account_Count_Device_History(AccountID, Count)
    WITH cte_AccountID AS (
		SELECT DISTINCT AccountID
        FROM Temp_NewAccountDevice
    )
    SELECT 	nad.AccountID
		,	COUNT(nad.AssociationID) AS Count
    FROM cte_AccountID AS cte
		INNER JOIN DCS_DataCenter.NewAccountDevice PARTITION(p10000000) AS nad ON nad.AccountID = cte.AccountID
	WHERE nad.AssociationID < lv_MinID
	GROUP BY nad.AccountID;
    
    INSERT INTO Temp_NewAccountDevice_Validated(AssociationID, AccountID)
    SELECT 	tmp.AssociationID
		,	tmp.AccountID
	FROM Temp_Account_Count_Device_History AS tmpH
		INNER JOIN Temp_NewAccountDevice AS tmp ON tmp.AccountID = tmpH.AccountID;
        
	DELETE tmp
    FROM Temp_NewAccountDevice AS tmp
		INNER JOIN Temp_NewAccountDevice_Validated AS tmpV ON tmpV.AssociationID = tmp.AssociationID;
        
    /*****Check INTO BATCH****************************************************/
    INSERT INTO Temp_Account_MinID(MinID, AccountID)
    SELECT 	MIN(tmp.AssociationID) as MinID
		,	tmp.AccountID
	FROM Temp_NewAccountDevice AS tmp
	GROUP BY tmp.AccountID;
    
    INSERT INTO Temp_NewAccountDevice_Validated(AssociationID, AccountID)
    SELECT 	tmp.AssociationID
		,	tmp.AccountID
    FROM Temp_NewAccountDevice AS tmp
	WHERE tmp.AssociationID NOT IN (SELECT MinID FROM Temp_Account_MinID);
        
    /*****Return DATA****************************************************/
    SELECT 	nad.AssociationID
		,	nad.RawTransID AS TransID
		,	nad.LoginName
		,	nad.TransTime
		,	nad.IP
		,	ua.UserAgent
		,	ua.OS
		,	ua.Browser
		,	dt.DeviceTypeName
	FROM Temp_NewAccountDevice_Validated AS tmp
		INNER JOIN DCS_DataCenter.NewAccountDevice PARTITION(p10000000) AS nad ON nad.AssociationID = tmp.AssociationID
		LEFT JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = nad.UserAgentKey
		LEFT JOIN DCS_DataCenter.DeviceType AS dt ON dt.DeviceTypeID = ua.DeviceTypeID;
        
	SELECT 	lv_MinID AS MinID
		,	lv_MaxID AS MaxID;
END$$
DELIMITER ;