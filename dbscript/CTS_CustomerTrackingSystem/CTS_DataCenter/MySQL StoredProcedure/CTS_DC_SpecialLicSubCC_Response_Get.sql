/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_SpecialLicSubCC_Response_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialLicSubCC_Response_Get`(
		IN ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250514@Casey.Huynh
		Task:	 	SpecialLicSubCC Scan Get
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250514@Casey.Huynh: 	Created [Redmine ID: #226847]

		Param's Explanation (filtered by): 

		Example:
			CALL CTS_DC_SpecialLicSubCC_Response_Get(@ip_BatchSize:=3);
	*/    
    DECLARE CONST_PROCESSSTATUS_CLASSIFI_COMPLETE		TINYINT DEFAULT 2;
    DECLARE CONST_PROCESSSTATUS_RESPONESE_FAIL			TINYINT DEFAULT 3;
    DECLARE CONST_STATICLIST_STATUSCODE					TINYINT DEFAULT 26;
      
	SELECT 	cus.ID
        ,	cus.CustID
        ,	cus.APICustomerClass
        ,	cus.LatestCustomerClass
        ,	cus.StatusCode
        ,	stl.ItemNameDisplay
	FROM CTS_DataCenter.Customer_SpecialLicSubCC AS cus
		INNER JOIN CTS_DataCenter.StaticList AS stl ON stl.ItemValue = cus.StatusCode
	WHERE cus.ProcessStatus IN (CONST_PROCESSSTATUS_CLASSIFI_COMPLETE, CONST_PROCESSSTATUS_RESPONESE_FAIL)
		AND stl.ListID = CONST_STATICLIST_STATUSCODE
	ORDER BY cus.ID ASC
	LIMIT ip_BatchSize;

END$$
DELIMITER ;
