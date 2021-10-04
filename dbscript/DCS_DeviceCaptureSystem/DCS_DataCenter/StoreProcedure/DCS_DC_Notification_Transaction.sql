/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Notification_Transaction`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Notification_Transaction`(
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210930@Casey.Huynh
	    Task : GET Sum Trans
	    DB: DCS_DataCenter (Slave)
	    Original:

	    Revisions:
			-	20210930@Casey.Huynh: Created [Redmine ID: 161528]
			
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_Notification_Transaction();

    */
	DECLARE lv_Yesterday DATETIME;
    DECLARE lv_PreYesterday DATETIME;
    
	SET lv_Yesterday = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);
    SET lv_PreYesterday = DATE_SUB(lv_Yesterday, INTERVAL 1 DAY);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PreYesterday;
    CREATE TEMPORARY TABLE Temp_PreYesterday(
			SubscriberID INT
        ,	TransTotal	INT UNSIGNED
        
        ,	PRIMARY KEY Temp_Yesterday(SubscriberID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Yesterday;
    CREATE TEMPORARY TABLE Temp_Yesterday LIKE Temp_PreYesterday;
    
    INSERT INTO Temp_PreYesterday(SubscriberID, TransTotal)
    SELECT	srt.SubscriberID
		,	srt.TransTotal
	FROM	DCS_DataCenter.SumRawTransaction AS srt
    WHERE 	srt.TransDate = lv_PreYesterday;
    
	INSERT INTO Temp_Yesterday(SubscriberID, TransTotal)
    SELECT	srt.SubscriberID
		,	srt.TransTotal
	FROM	DCS_DataCenter.SumRawTransaction AS srt
    WHERE 	srt.TransDate = lv_Yesterday;

    /* Total Trans (Yesterday)/Total Trans (Yesterday - 1) < 50% */
    SELECT 	CONCAT(sb.SubscriberName) AS YesterdayLess50Percent
    FROM Temp_PreYesterday AS tmpPy
    INNER JOIN Temp_Yesterday AS tmpYs ON tmpPy.SubscriberID = tmpYs.SubscriberID
    INNER JOIN CTS_Admin.Subscriber AS sb ON tmpPy.SubscriberID = sb.SubscriberID
    WHERE tmpYs.TransTotal/tmpPy.TransTotal < 0.5 AND tmpPy.TransTotal > 0; 
    
    /* Total Trans (Yesterday) = 0 and Total Trans (Yesterday - 1) > 0 */
    SELECT 	CONCAT(sb.SubscriberName) AS YesterdayZero
    FROM Temp_PreYesterday AS tmpPy
    INNER JOIN Temp_Yesterday AS tmpYs ON tmpPy.SubscriberID = tmpYs.SubscriberID
    INNER JOIN CTS_Admin.Subscriber AS sb ON tmpPy.SubscriberID = sb.SubscriberID
    WHERE tmpYs.TransTotal = 0 AND tmpPy.TransTotal > 0;
    
	/* Valid Trans(Yesterday)/Total Trans(Yesteday) <50% */
    SELECT 	CONCAT(sb.SubscriberName) AS ValidLess50Percent
    FROM Temp_Yesterday AS tmpYs
    LEFT JOIN DCS_DataCenter.SumTransaction AS st ON st.SubscriberID = tmpYs.SubscriberID AND st.TransDate = lv_Yesterday 
    INNER JOIN CTS_Admin.Subscriber AS sb ON tmpYs.SubscriberID = sb.SubscriberID
    WHERE IFNULL(st.ValidTotal,0)/tmpYs.TransTotal < 0.5 AND tmpYs.TransTotal > 0;
    
END$$
DELIMITER ;
