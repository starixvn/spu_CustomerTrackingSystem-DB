/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_SumRawTransaction_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_SumRawTransaction_Update`(
		IN ip_SumJson		JSON  
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210930@Casey.Huynh
	    Task : Update TransSum
	    DB: DCS_DataCenter (Master)
	    Original:

	    Revisions:		    
        
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_SumRawTransaction_Update('[{"TransDate":"2021-09-28", "SubscriberID":2, "TransTotal":2800}
														,{"TransDate":"2021-09-29", "SubscriberID":2, "TransTotal":2900}]');			]');

    */
    
    DECLARE lv_MaxTransDate DATETIME;
    DECLARE lv_Today DATETIME DEFAULT CURRENT_DATE();
    
    SELECT MAX(srt.TransDate) 
    INTO lv_MaxTransDate
    FROM DCS_DataCenter.SumRawTransaction AS srt;
    
    SET lv_MaxTransDate = IFNULL(lv_MaxTransDate,DATE_SUB(lv_Today, INTERVAL 1 DAY));
    
    WHILE lv_MaxTransDate <= lv_Today DO    
		SET lv_MaxTransDate = DATE_ADD(lv_MaxTransDate, INTERVAL 1 DAY);
        
        INSERT IGNORE INTO DCS_DataCenter.SumRawTransaction(TransDate, SubscriberID, TransTotal)    
		SELECT 	lv_MaxTransDate
				, sub.SubscriberID
				, 0
		FROM CTS_Admin.Subscriber AS sub
		WHERE sub.DCSStatus = 1;
        
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
