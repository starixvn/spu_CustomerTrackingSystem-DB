/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Init`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Init`(
		IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
sp : BEGIN
/*
		Created:	20220518@Aries.Nguyen
		Task:		Init data
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220518@Aries.Nguyen [#220204]: Created
            
        Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Init(1000);
	*/   
    DECLARE	lv_LastCTSCustID 		BIGINT;
    DECLARE	lv_MaxCTSCustID 		BIGINT;

    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo(	  
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		,	IsLicensee		BIT
		,	IsInternal		BIT
	);  

	SELECT ParameterValue
	INTO lv_LastCTSCustID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 1000;
    
    IF lv_LastCTSCustID < 0 THEN
		LEAVE sp;
    END IF;

	INSERT INTO Temp_CustInfo(CTSCustID, IsLicensee, IsInternal)
	SELECT 	DISTINCT
			CTSCustID
		, 	CASE WHEN mss.SubscriberGroupID = 2 THEN 1 
				 WHEN mss.SubscriberGroupID IS NULL THEN NULL
			ELSE 0 END AS IsLicensee
		,	CASE WHEN cust.UserName Like '%CashOut' OR stl.ItemID IS NOT NULL OR (cust.Recommend IN (52466,5707545) AND cust.RoleID = 1)
				 THEN 1 
			ELSE 0 END AS IsInternal
	FROM CTS_DataCenter.CTSCustomer AS cust
	LEFT JOIN CTS_DataCenter.MappingSubscriberSite AS mss ON cust.SiteID = mss.SiteID
	LEFT JOIN CTS_DataCenter.StaticList AS stl ON stl.ItemID = cust.SiteID AND stl.ListID = 11
	WHERE cust.CTSCustID > lv_LastCTSCustID
    ORDER BY cust.CTSCustID ASC
	LIMIT ip_BatchSize;

	UPDATE CTSCustomer AS cust
	INNER JOIN Temp_CustInfo AS tmp ON cust.CTSCustID  = tmp.CTSCustID
	SET 	cust.IsInternal = tmp.IsInternal
		,	cust.IsLicensee = tmp.IsLicensee;

	SELECT MAX(CTSCustID)
	INTO  lv_MaxCTSCustID
	FROM Temp_CustInfo;
    
    IF lv_MaxCTSCustID IS NULL THEN
		SET lv_MaxCTSCustID = lv_LastCTSCustID;
	END IF;
    
    UPDATE CTS_DataCenter.SystemParameter
	SET ParameterValue = lv_MaxCTSCustID
	WHERE  ParameterID = 1000;
    
END$$
DELIMITER ;