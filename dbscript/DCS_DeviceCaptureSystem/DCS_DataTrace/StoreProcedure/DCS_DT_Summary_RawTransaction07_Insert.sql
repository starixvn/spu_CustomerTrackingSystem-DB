/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_RawTransaction07_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_RawTransaction07_Insert`(
    IN ip_Size INT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231003@Jonathan.Doan
	Task : Insert data into RawTransaction07
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20240314@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Summary_RawTransaction07_Insert(10);
	*/
    DECLARE CONST_RAWTRANS07_TRANSID 				INT 		DEFAULT 5;
    
    DECLARE lv_MaxTransID  			BIGINT UNSIGNED;
    SET lv_MaxTransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_RAWTRANS07_TRANSID);
    
    INSERT IGNORE INTO DCS_DataTrace.RawTransaction07(TransID, LoginName, TransTime, SubscriberID, AccountID, DeviceID, Flagged, CreatedDate, RawUserAgentID, FPDeviceID)
    SELECT 	TransID
		,	LoginName
        ,	TransTime
        ,	SubscriberID
        ,	AccountID
        ,	DeviceID
        ,	Flagged
        ,	CreatedDate
        ,	RawUserAgentID
        ,	FPDeviceID
	FROM DCS_DataCenter.Transaction07
    WHERE TransID > lv_MaxTransID
    ORDER BY TransID ASC
    LIMIT ip_Size;
    
    SET lv_MaxTransID = (SELECT MAX(TransID) FROM DCS_DataTrace.RawTransaction07);
    
    IF(lv_MaxTransID IS NOT NULL AND lv_MaxTransID > 0) THEN
        UPDATE DCS_DataTrace.SystemSetting 
        SET VValue = lv_MaxTransID
        WHERE ID = CONST_RAWTRANS07_TRANSID;
    END IF;
END$$
DELIMITER ;
