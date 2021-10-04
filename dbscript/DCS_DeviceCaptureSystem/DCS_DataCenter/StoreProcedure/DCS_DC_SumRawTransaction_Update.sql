/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_SumRawTransaction_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_SumRawTransaction_Update`(
		IN ip_SumJson	JSON  
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210930@Casey.Huynh
	    Task : Update TransSum
	    DB: DCS_DataCenter (Master)
	    Original:

	    Revisions:		    
			-	20210930@Casey.Huynh: Created [Redmine ID: 161528]
            
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_SumRawTransaction_Update('[{"TransDate":"2021-09-30", "SubscriberID":2, "TransTotal":2800}
														,{"TransDate":"2021-09-30", "SubscriberID":2, "TransTotal":2900}]');
    */
    
    DECLARE lv_LastTransDate DATETIME;
    DECLARE lv_Today DATETIME DEFAULT CURRENT_DATE();
    
    SELECT VValue
    INTO lv_LastTransDate
    FROM DCS_DataCenter.SystemSetting AS ss
    WHERE ID = 13;   
   
    #=========INITIAL IF NOT EXISTS==============================================
    WHILE lv_LastTransDate < lv_Today DO 

        SET lv_LastTransDate = DATE_ADD(lv_LastTransDate, INTERVAL 1 DAY);
        
        INSERT IGNORE INTO DCS_DataCenter.SumRawTransaction(TransDate, SubscriberID, TransTotal)    
		SELECT 	lv_LastTransDate
			,	sub.SubscriberID
			,	0
		FROM CTS_Admin.Subscriber AS sub
		WHERE sub.DCSStatus = 1;      
        
        UPDATE DCS_DataCenter.SystemSetting AS ss
		SET ss.VValue = lv_LastTransDate
        WHERE ID = 13;       
        
    END WHILE;
    
    INSERT INTO DCS_DataCenter.SumRawTransaction(TransDate, SubscriberID, TransTotal)
	SELECT 	js.TransDate
		,	js.SubscriberID
        ,	js.TransSum
		FROM JSON_TABLE(ip_SumJson,
			"$[*]" COLUMNS(
				TransDate		DATETIME PATH "$.TransDate"
            ,   SubscriberID	INT PATH "$.SubscriberID" 
			,	TransSum		INT PATH "$.TransTotal" 
			)
		) AS js
	ON DUPLICATE KEY UPDATE TransTotal = TransTotal + js.TransSum;    
    
END$$
DELIMITER ;
