USE `CTS_DataCenter`;
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_AssociatedAccountMonitor`;

DELIMITER $$
CREATE PROCEDURE `CTS_DC_RPT_AssociatedAccountMonitor`()
BEGIN
	/*
		Created:	20200706@Long.Luu
		Task:		Insert Associated Account Monitor [Redmine ID: #134652]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200706@Long.Luu: Created [Redmine ID: #134652]
        
		Param's Explanation (filtered by):
	*/

    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT 	c.CTSCustID
		,	c.CustID
        ,	c.UserName
        ,	c.UserName2
        ,	CASE 
				WHEN c.CustStatusID = 1 THEN 'Open'
                WHEN c.CustStatusID = 2 THEN 'Disabled'
                WHEN c.CustStatusID = 3 THEN 'Closed'
                WHEN c.CustStatusID = 4 THEN 'Suspended'
                WHEN c.CustStatusID = 11 THEN 'Active'
                WHEN c.CustStatusID = 12 THEN 'Inactive'
                WHEN c.CustStatusID = 13 THEN 'ViewOnly'
                WHEN c.CustStatusID = 14 THEN 'Suspended'
			END AS AccountStatus
        ,	s.SubscriberName
        ,	a.Remark
        ,	l.UserName AS CreatedBy
        ,	c.CreatedTime
    FROM CTS_DataCenter.AssociatedAccountMonitor AS a
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID
        INNER JOIN CTS_Admin.Subscriber AS s ON c.SubscriberID = s.SubscriberID
        INNER JOIN CTS_Admin.CTSUser AS l ON a.CreatedBy = l.UserID;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$

DELIMITER ;

