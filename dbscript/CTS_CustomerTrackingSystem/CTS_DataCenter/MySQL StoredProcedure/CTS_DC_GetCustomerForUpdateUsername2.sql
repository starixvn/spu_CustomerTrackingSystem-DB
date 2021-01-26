/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetCustomerForUpdateUsername2`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustomerForUpdateUsername2`(IN ip_Size int,IN ip_CustID bigint,IN ip_IsUpdateCustsub tinyint)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200112@Harvey
		Task:		Get customer from CTS Customer for updating username2
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200421@Harvey:	Get customer for update SubscriberID - [Redmine: #132705]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			
		Param's Explanation (filtered by):         
        
        CALL CTS_DC_GetCustomerForUpdateUsername2 (500,0,1)
	*/

	IF ip_IsUpdateCustsub = 0 THEN
		SELECT CTSCustID
			,CustID
			,CustSubID
		FROM CTSCustomer
		WHERE (UserName2 IS NULL OR SubscriberID IS NULL)
			AND CustID > ip_CustID
			AND CustSubID = 0
		ORDER BY CustID
		LIMIT ip_Size;
	ELSE
		SELECT CTSCustID
			,CustID
			,CustSubID
		FROM CTSCustomer
		WHERE (UserName2 IS NULL OR SubscriberID IS NULL)
			AND CustID > 0
			AND CustSubID > ip_CustID
		ORDER BY CustSubID
		LIMIT ip_Size;
	END IF;

END$$

DELIMITER ;
