/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_GetByCTSCustID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_GetByCTSCustID`(
	IN ip_CTSCustID BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191217@Marcus
		Task :		Get LastLoginTime 
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20191217@Marcus : Created
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
            - 20210423@Casey.Huynh: Get cust status and Danger from CTS instead of MainDB [Redmine ID: #152259] 
			- 20220523@Aries.Nguyen: Return IsLicensee, IsInternal  [Redmine ID: #152259] 

		Param's Explanation (filtered by):
	*/
    
	 SELECT	cus.CustID
		,	cus.SubscriberID
		,	sub.SubscriberName
		,	cus.CustSubID
		,	cus.LastLoginTime
		,	cus.UserName
        ,	cus.UserName2
		,	cus.CreatedDate
		,	cus.RoleID	
		, 	cus.CustStatusID
		, 	CASE WHEN st.ItemID IS NULL THEN 'N/A' ELSE st.ItemName END AS CustStatusName
		, 	cus.Danger1
		, 	cus.Danger2
		, 	cus.Danger3
		,	cus.IsLicensee
		,	cus.IsInternal 
	FROM		CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN  CTS_Admin.Subscriber AS sub ON cus.SubscriberID	= sub.SubscriberID
		LEFT JOIN CTS_DataCenter.StaticList AS st ON st.ListID = 1 AND cus.CustStatusID = st.ItemID
	WHERE  cus.CTSCustID = ip_CTSCustID;
END$$
DELIMITER ;