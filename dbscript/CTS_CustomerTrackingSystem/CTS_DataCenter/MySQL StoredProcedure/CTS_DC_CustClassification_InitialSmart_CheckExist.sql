/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_InitialSmart_CheckExist`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InitialSmart_CheckExist`(
        IN ip_CustIDs	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20240531@Thomas.Nguyen
		Task:	 	Check cust exist in initial smart source table for rescan flow
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20240531@Thomas.Nguyen: Created [Redmine ID: #199345]
            
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_CheckExist('1275,1276,1277,1280');
	*/
    DECLARE  CONST_CATEGORYID_INITIALSMART	INT DEFAULT 66;

	SELECT	tmp.CustID
        ,	cus.CTSCustID
        ,	cus.SubscriberID
        ,	cus.RoleID
        ,   cus.IsLicensee
        ,	CONST_CATEGORYID_INITIALSMART AS CategoryID
        ,	CONST_CATEGORYID_INITIALSMART AS CategoryGroup
        ,   cs.Probability
        ,   cs.PredictTime AS DetectedDate
	FROM JSON_TABLE(REPLACE(JSON_ARRAY(ip_CustIDs), ',', '","'), 
						'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
							) AS tmp
		INNER JOIN CTS_DataCenter.Customer_InitialSmart AS cs ON cs.CustID = tmp.CustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.IsInternal = 0;

END$$	
DELIMITER ;