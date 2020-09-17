DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_Subscriber_ValidatePrefix $$

CREATE PROCEDURE `CTS_DC_Subscriber_ValidatePrefix`(
		IN ip_SubscriberPrefix 			VARCHAR(50)
)
BEGIN
	/*

		Created:	20200917@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
			- 20200917@Roger.Le: Created [Redmine ID: #138102]
            
		Param's Explanation:
	*/ 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;
	CREATE TEMPORARY TABLE Temp_Subscriber(
			SubscriberPrefix 		VARCHAR(30)
        
        ,	INDEX		IX_Subscriber_SubscriberPrefix(SubscriberPrefix) 
    );
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    INSERT INTO Temp_Subscriber (SubscriberPrefix)
	VALUES (ip_SubscriberPrefix);
    
	SELECT sub.SubscriberID
		, sub.SubscriberName
        , sub.SubscriberPrefix
        , sg.SubscriberGroupName
        , s.SiteID
        , s.SiteName
    FROM  CTS_Admin.Subscriber AS sub
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS s ON s.SubscriberID = sub.SubscriberID
        INNER JOIN Temp_Subscriber AS tmp ON tmp.SubscriberPrefix = sub.SubscriberPrefix
        INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON s.SubscriberGroupID = sg.SubscriberGroupID
    WHERE	sub.SubscriberStatus <> -1
	ORDER BY sub.SubscriberID ASC;
    
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$
DELIMITER ;