/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_SumTransaction07_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_SumTransaction07_Get`(
	IN ip_Size	INT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210930@Casey.Huynh
	    Task : GET Sum Trans
	    DB: DCS_DataCenter (Slave)
	    Original:

	    Revisions:		    
        
	    Param's Explanation (filtered by):
        
        Example: 

    */
	DECLARE lv_MaxTransID BIGINT UNSIGNED;
    DECLARE lv_LastTransID BIGINT UNSIGNED;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			TransDate		DATETIME
        ,	SubscriberID 	INT
        ,	DeviceID		BIGINT UNSIGNED
        ,	DeviceStatus	TINYINT
        ,	Flagged			INT
        ,	TransID			BIGINT UNSIGNED
        ,	AccountID		BIGINT
        
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
        
        ,	PRIMARY KEY PK_Temp_ValidTrans(TransDate,SubscriberID,TransID)
        ,	INDEX AccountID(AccountID)
        
    );
    
    SET lv_LastTransID = (SELECT VValue FROM DCS_DataCenter.SystemSetting WHERE ID = 11);
    
    SELECT MAX(tmp.TransID) 
    INTO lv_MaxTransID
    FROM (SELECT TransID FROM DCS_DataCenter.Transaction07 WHERE TransID > lv_LastTransID LIMIT ip_Size) AS tmp;
    
    SELECT IFNULL(lv_MaxTransID,0);
    
    SELECT lv_MaxTransID;
    
    IF lv_MaxTransID IS NOT NULL THEN
    
		INSERT INTO Temp_Trans(TransID, TransDate,SubscriberID, DeviceID, DeviceStatus, Flagged, AccountID)
		SELECT TransID, CreatedDate, SubscriberID, DeviceID, DeviceStatus, Flagged , AccountID
		FROM DCS_DataCenter.Transaction07 AS ts
		WHERE TransID BETWEEN lv_LastTransID AND lv_MaxTransID;
       
		INSERT INTO Temp_ValidTrans(TransID, TransDate,SubscriberID, DeviceID, DeviceStatus, Flagged, AccountID)
		SELECT ts.TransID, ts.TransDate,ts.SubscriberID, ts.DeviceID, ts.DeviceStatus, ts.Flagged, ts.AccountID
		FROM Temp_Trans AS ts
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dc ON ts.AccountID = dc.AccountID;        
		
		SELECT TransDate
			,	SubscriberId
			,	COUNT(1) AS ValidTotal
            ,	SUM(CASE WHEN DeviceID > 0 THEN 1 ELSE 0 END) AS ValidTotalDevice
			,	SUM(CASE WHEN DeviceStatus = 1 THEN 1 ELSE 0 END) AS ValidDeviceStatusNew
			,	SUM(CASE WHEN DeviceStatus = 2 THEN 1 ELSE 0 END) AS ValidDeviceStatusOld
			,	SUM(CASE WHEN DeviceStatus = 3 THEN 1 ELSE 0 END) AS ValidDevoceStatusRecover  
            ,	SUM(CASE WHEN Flagged > 1 THEN 1 ELSE 0 END) AS ValidBrowserless
		FROM Temp_ValidTrans
		GROUP BY TransDate,SubscriberID;          
        
    END IF;
END$$
DELIMITER ;
