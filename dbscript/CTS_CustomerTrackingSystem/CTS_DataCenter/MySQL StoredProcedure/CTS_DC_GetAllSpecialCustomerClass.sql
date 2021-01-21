/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetAllSpecialCustomerClass`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetAllSpecialCustomerClass`(IN ip_IsGetAllInfo bit)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200905@Long.Luu
		Task:		Insert special customer class
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200905@Long.Luu [140996]: Created
           - 20200908@Irena.Vo [141020]: Exclude VVIP, Pin category in list
           - 20020915@Irena.Vo [141020]: Enhance sort data
		   - 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
		   
		Param's Explanation (filtered by):
	*/        

    IF (ip_IsGetAllInfo = 1) THEN
		SELECT 	s.CTSCustID
			,	s.CustID
			, 	c.UserName
			,	s.RootCTSCustID
			, 	sub.SubscriberName
			, 	s.CustomerClass
			,	u.UserName AS CreatedBy
			,	s.CreatedDate
		FROM CTS_DataCenter.SpecialCustomerClass AS s
			INNER JOIN CTS_DataCenter.CTSCustomer AS c ON s.CTSCustID = c.CTSCustID
			INNER JOIN CTS_Admin.Subscriber AS sub ON s.SubscriberID = sub.SubscriberID
			INNER JOIN CTS_Admin.CTSUser AS u ON s.CreatedBy = u.UserID
		WHERE s.CreatedFromFunction = 1
        ORDER BY s.CreatedDate DESC; -- Enhance sort data
    ELSE
		SELECT CustID
		FROM CTS_DataCenter.SpecialCustomerClass
        WHERE CreatedFromFunction IN (1, 11, 21); -- Exclude Normal, VVIP, Pin Category customer class.
    END IF;
   
END$$

DELIMITER ;
