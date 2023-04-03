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
    DECLARE lv_MaxID BIGINT UNSIGNED;
    
    SET lv_SystemSettingVValue 	= IFNULL((SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE VGroup=lv_SystemSettingVGroup AND VName=lv_SystemSettingVName), 0);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction_Validated;
    DROP TEMPORARY TABLE IF EXISTS Temp_Account_Exists_History;
    DROP TEMPORARY TABLE IF EXISTS Temp_Account_MinID;
    
    CREATE TEMPORARY TABLE Temp_Transaction(
			ID BIGINT UNSIGNED PRIMARY KEY
        ,	AccountID BIGINT UNSIGNED
        
        ,	INDEX 	IX_Temp_Transaction_AccountID(AccountID)
    );
    
    CREATE TEMPORARY TABLE Temp_Transaction_Validated(
			ID BIGINT UNSIGNED PRIMARY KEY
        ,	AccountID BIGINT UNSIGNED
    );
    
    CREATE TEMPORARY TABLE Temp_Account_Exists_History(
			AccountID BIGINT UNSIGNED PRIMARY KEY
    );
    
    CREATE TEMPORARY TABLE Temp_Account_MinID(
			ID BIGINT UNSIGNED PRIMARY KEY
        ,	AccountID BIGINT UNSIGNED
    );
    
    INSERT INTO Temp_Transaction(ID, AccountID)
    SELECT 	trans.ID
		,	trans.AccountID
	FROM DCS_DataCenter.AbnormalTransasction AS trans
	WHERE trans.ID > lv_SystemSettingVValue
    ORDER BY trans.ID
    LIMIT ip_Size;
    
    SELECT IFNULL(MAX(tmp.ID),0)
    INTO lv_MaxID
	FROM Temp_Transaction AS tmp;
    
    INSERT INTO Temp_Account_Exists_History(AccountID)
    WITH cte_AccountID AS (
		SELECT DISTINCT AccountID
        FROM Temp_Transaction
    )
    SELECT 	cte.AccountID
    FROM cte_AccountID AS cte
    WHERE EXISTS (	SELECT 1 
					FROM DCS_DataCenter.AbnormalTransasction AS trans 
                    WHERE trans.ID < lv_SystemSettingVValue + 1 
						AND trans.AccountID = cte.AccountID
				);
    
    INSERT INTO Temp_Transaction_Validated(ID, AccountID)
    SELECT 	tmp.ID
		,	tmp.AccountID
	FROM Temp_Account_Exists_History AS tmpA
		INNER JOIN Temp_Transaction AS tmp ON tmp.AccountID = tmpA.AccountID;
        
	DELETE tmp
    FROM Temp_Transaction AS tmp
		INNER JOIN Temp_Transaction_Validated AS tmpV ON tmpV.ID = tmp.ID;
        
    /*****Check INTO BATCH****************************************************/
    INSERT INTO Temp_Account_MinID(ID, AccountID)
    SELECT 	MIN(tmp.ID) as ID
		,	tmp.AccountID
	FROM Temp_Transaction AS tmp
	GROUP BY tmp.AccountID;
    
    INSERT INTO Temp_Transaction_Validated(ID, AccountID)
    SELECT 	tmp.ID
		,	tmp.AccountID
    FROM Temp_Transaction AS tmp
	WHERE tmp.ID NOT IN (SELECT ID FROM Temp_Account_MinID);
        
    /*****Return DATA****************************************************/
    SELECT 	trans.ID
		,	trans.TransID
		,	trans.LoginName
		,	trans.TransTime
		,	trans.IP
		,	ua.UserAgent
		,	ua.OS
		,	ua.Browser
		,	dt.DeviceTypeName
	FROM Temp_Transaction_Validated AS tmp
		INNER JOIN DCS_DataCenter.AbnormalTransasction AS trans ON trans.ID = tmp.ID
		LEFT JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
		LEFT JOIN DCS_DataCenter.DeviceType AS dt ON dt.DeviceTypeID = ua.DeviceTypeID;
        
	SELECT lv_MaxID AS MaxID;
END$$
DELIMITER ;
