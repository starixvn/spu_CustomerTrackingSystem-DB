/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_RPT_Transaction`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_RPT_Transaction`(
		IN ip_FromDate 			DATETIME
    ,	IN ip_ToDate 			DATETIME
    ,	IN ip_SubscriberList	TEXT
	,	IN ip_Skip 				INT
    ,	IN ip_Take 				INT
    
    ,	OUT op_TotalItems		INT
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
        
        Example: CALL DCS_DC_Notification_Transaction(5000);

    */    
    DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;
    CREATE TEMPORARY TABLE Temp_Subscriber(
			SubscriberID INT PRIMARY KEY
		,	SubscriberName VARCHAR(50)
    );
    
    SET @sql = CONCAT('	INSERT INTO Temp_Subscriber(SubscriberID, SubscriberName)
						SELECT SubscriberID, SubscriberName
						FROM CTS_Admin.Subscriber 
						WHERE SubscriberID IN (',ip_SubscriberList,')');
                        
    PREPARE	stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SELECT	SQL_CALC_FOUND_ROWS
			tmpSb.SubscriberName AS 'Subscriber'
		,	SUM(rt.TransTotal) AS 'Total Trans'
		,	SUM(IFNULL(ts.ValidTotal,0)) AS 'Total Valid Trans'
		,	SUM(IFNULL(ts.ValidDeviceStatusNew,0)) AS 'Valid Trans (New Device)'
		,	SUM(IFNULL(ts.ValidDeviceStatusOld,0)) AS 'Valid Trans (Old Device)'
		,	SUM(IFNULL(ts.ValidDeviceStatusRecover,0)) AS 'Valid Trans (Recover Device)'
		,	SUM(IFNULL(ts.ValidNoDevice,0)) AS 'Valid Trans (No Device)'  
		,	SUM(rt.TransTotal) - SUM(IFNULL(ts.ValidNoDevice,0)) AS 'Invalid Trans'  
		,	SUM(IFNULL(ts.ValidBrowserless,0)) AS 'Browserless'  
	FROM DCS_DataCenter.SumRawTransaction AS rt
		LEFT JOIN DCS_DataCenter.SumTransaction AS ts ON rt.TransDate = ts.TransDate AND rt.SubscriberID = ts.SubscriberID
		INNER JOIN Temp_Subscriber AS tmpSb ON rt.SubscriberID = tmpSb.SubscriberID
	WHERE rt.TransDate BETWEEN ip_FromDate AND ip_ToDate
	GROUP BY tmpSb.SubscriberName
	ORDER BY tmpSb.SubscriberName
	LIMIT ip_Take
	OFFSET ip_Skip;
        
	SET op_TotalItems = FOUND_ROWS();
    
END$$
DELIMITER ;
