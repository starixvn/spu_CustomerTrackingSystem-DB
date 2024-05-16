/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_InitialGB_GetCustInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InitialGB_GetCustInfo`(
	IN ip_CustIDs LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240422@Thomas.Nguyen
		Task :		Get cust info for initial group betting
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20240422@Thomas.Nguyen: 		Created [Redmine ID: #200854]
			
		Param's Explanation (filtered by):
        		
		Example:
			-	CALL CTS_DC_CustClassification_InitialGB_GetCustInfo('1,2,987385,8498955,21007469,1295,916740,2812695');
	*/

	DECLARE	CONST_CATEGORY_INITIALGB        INT DEFAULT 67;

	SELECT	cus.CTSCustID
		, 	cus.CustID
		,	cus.RoleID
		,	cus.SubscriberID
		,	CONST_CATEGORY_INITIALGB AS CategoryID
		,	CONST_CATEGORY_INITIALGB AS CategoryGroup
		,	cus.IsLicensee
	FROM JSON_TABLE(REPLACE(JSON_ARRAY(ip_CustIDs), ',', '","'), 
						'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
						) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.IsInternal = 0 AND cus.IsLicensee = 1;
      
END$$

DELIMITER ;