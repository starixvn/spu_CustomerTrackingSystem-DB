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
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
	SELECT sub.SubscriberID
		, sub.SubscriberName
    FROM  	CTS_Admin.Subscriber AS sub
    WHERE	sub.SubscriberPrefix	=	ip_SubscriberPrefix
	ORDER BY sub.SubscriberID ASC;
    
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$
DELIMITER ;