/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_SumTransaction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_SumTransaction_Get`(
)
    SQL SECURITY INVOKER
sp: BEGIN
    /*
	    Created: 20210930@Casey.Huynh
	    Task : GET Sum Trans
	    DB: DCS_DataCenter (Slave)
	    Original:

	    Revisions:		    
        	-	20210930@Casey.Huynh: Created [Redmine ID: 161528]
            -	202110150@Casey.Huynh: Update Get TransID from LastTransID + 1 [Redmine ID: 161528]
            -   20211214@Aries.Nguyen: Enrich the information on customer profile [Redmine ID: #165105]

	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_SumTransaction_Get(5000);

    */
	DECLARE lv_BatchSize BIGINT UNSIGNED;
    DECLARE lv_LastTransID BIGINT UNSIGNED;
	DECLARE lv_MaxTransID BIGINT UNSIGNED;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			TransDate		DATETIME
        ,	SubscriberID 	INT
        ,	DeviceID		BIGINT UNSIGNED
        ,	DeviceStatus	TINYINT
        ,	Flagged			INT
        ,	TransID			BIGINT UNSIGNED
        ,	AccountID		BIGINT UNSIGNED
        ,	UserAgentKey	VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci
        ,   IP				VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci 
        ,	PRIMARY KEY PK_Temp_ValidTrans(TransDate,SubscriberID,TransID)
        ,	INDEX AccountID(AccountID)
        
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ValidTrans;
    CREATE TEMPORARY TABLE Temp_ValidTrans(
			TransDate		DATETIME
        ,	SubscriberID 	INT
        ,	DeviceID		BIGINT UNSIGNED
        ,	DeviceStatus	TINYINT
        ,	Flagged			INT
        ,	TransID			BIGINT UNSIGNED
        ,	AccountID		BIGINT
        ,	UserAgentKey	VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci
        ,   IP				VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci 
        
        ,	PRIMARY KEY PK_Temp_ValidTrans(TransDate,SubscriberID,TransID)
        ,	INDEX AccountID(AccountID)
        
    );
    
    SELECT VValue
    INTO lv_LastTransID
    FROM DCS_DataCenter.SystemSetting WHERE ID = 11;
    
    SELECT VValue
    INTO lv_BatchSize
    FROM DCS_DataCenter.SystemSetting WHERE ID = 12;
    
    SELECT MAX(tmp.TransID) 
    INTO lv_MaxTransID
    FROM (SELECT TransID FROM DCS_DataCenter.Transaction07 WHERE TransID > lv_LastTransID ORDER BY TransID ASC LIMIT lv_BatchSize) AS tmp;
    
    SELECT IFNULL(lv_MaxTransID,0) AS MaxTransID;
    
    IF lv_MaxTransID IS NULL THEN
		LEAVE sp;
    END IF;
    
	INSERT INTO Temp_Trans(TransID, TransDate,SubscriberID, DeviceID, DeviceStatus, Flagged, AccountID, UserAgentKey, IP)
	SELECT 	TransID
		, 	CreatedDate
		, 	SubscriberID
		, 	DeviceID
		, 	DeviceStatus
		, 	Flagged
		, 	AccountID
		, 	UserAgentKey
		, 	IP
	FROM DCS_DataCenter.Transaction07 AS ts
	WHERE TransID BETWEEN lv_LastTransID + 1 AND lv_MaxTransID;
       
	INSERT INTO Temp_ValidTrans(TransID, TransDate,SubscriberID, DeviceID, DeviceStatus, Flagged, AccountID, UserAgentKey, IP)
	SELECT 	ts.TransID
		, 	ts.TransDate
        ,	ts.SubscriberID
        , 	ts.DeviceID
        , 	ts.DeviceStatus
        , 	ts.Flagged
        , 	ts.AccountID
        , 	ts.UserAgentKey
        , 	ts.IP
	FROM Temp_Trans AS ts
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dc ON ts.AccountID = dc.AccountID;        
		
	SELECT TransDate
		,	SubscriberID
		,	COUNT(1) AS ValidTotal
		,	SUM(CASE WHEN DeviceStatus IS NULL THEN 1 ELSE 0 END) AS ValidNoDevice
		,	SUM(CASE WHEN DeviceStatus = 1 THEN 1 ELSE 0 END) AS ValidDeviceStatusNew
		,	SUM(CASE WHEN DeviceStatus = 2 THEN 1 ELSE 0 END) AS ValidDeviceStatusOld
		,	SUM(CASE WHEN DeviceStatus = 3 THEN 1 ELSE 0 END) AS ValidDeviceStatusRecover  
		,	SUM(CASE WHEN Flagged > 1 THEN 1 ELSE 0 END) AS ValidBrowserless
	FROM Temp_ValidTrans
	GROUP BY TransDate
		,	 SubscriberID;   
	
    SELECT 	trans.AccountID
		,	trans.TransDate
        ,	SUM(CASE WHEN dv.GroupName = 'Mobile' THEN 1 ELSE 0 END) AS DeviceMobile
        ,	SUM(CASE WHEN dv.GroupName = 'Desktop' THEN 1 ELSE 0 END) AS DeviceDesktop
        ,	SUM(CASE WHEN dv.GroupName IS NULL OR  dv.GroupName = 'Others' THEN 1 ELSE 0 END) AS DeviceOthers
        ,	COUNT(1) AS TotalLogin
    FROM Temp_ValidTrans AS trans
		LEFT JOIN DCS_DataCenter.UserAgent  AS ua ON ua.UserAgentKey  = trans.UserAgentKey
        LEFT JOIN DCS_DataCenter.DeviceType AS dv ON dv.DeviceTypeID = ua.DeviceTypeID
	GROUP BY trans.AccountID
		,	 trans.TransDate;
	
     SELECT trans.AccountID
		,	MAX(trans.TransDate) AS TransDate
		,	trans.IP
	FROM Temp_ValidTrans AS trans
    GROUP BY trans.AccountID
        ,	 trans.IP;
	
    SELECT 	trans.AccountID
		,	MAX(trans.TransDate) AS TransDate
		,	trans.DeviceID
	FROM Temp_ValidTrans AS trans
    GROUP BY trans.AccountID
        ,	 trans.DeviceID;
END$$
DELIMITER ;
