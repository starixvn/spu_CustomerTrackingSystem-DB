/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsService,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustEvidence_GetByReasonId`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustEvidence_GetByReasonId`(
	IN  ip_InputCustomers JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220307@Irena.Vo
		Task:		Get Evidences from ReasonID
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220307@Irena.Vo: Created [Redmine ID: #159014]
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_CustEvidence_GetByReasonId('[{"CustID": 5940, "ReasonID": 28},{"CustID": 5940, "ReasonID": 102},
														{"CustID": 40290236, "ReasonID": 28},{"CustID": 40290236, "ReasonID": 102},
														{"CustID": 5941, "ReasonID": 29},
														{"CustID": 40290237, "ReasonID": 103}]');
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomer;    
	CREATE TEMPORARY TABLE Temp_InputCustomer(	  
			CustID					BIGINT UNSIGNED 
		,	ReasonID				SMALLINT	
        ,	PRIMARY KEY				PK_Temp_InputCustomer(CustID,ReasonID)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedCustomer;    
	CREATE TEMPORARY TABLE Temp_ExistedCustomer(	  
			CustID				BIGINT UNSIGNED
        , 	CTSCustID			BIGINT 
        ,	IsLicensee			BIT
        ,	ReasonID			SMALLINT	
        ,	PRIMARY KEY			PK_Temp_ExistedCustomer(CustID,IsLicensee,ReasonID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceMapping;    
	CREATE TEMPORARY TABLE Temp_EvidenceMapping(	  
			EvidenceID			BIGINT UNSIGNED
		,	EvidenceCode		VARCHAR(10) 
        ,	IsLicensee			BIT
        ,	ReasonID			SMALLINT
        ,	PRIMARY KEY			PK_Temp_EvidenceMapping(EvidenceID,IsLicensee,ReasonID)
    ); 
    
    /*	1: GET CUSTOMERS */
	INSERT IGNORE INTO Temp_InputCustomer(CustID, ReasonID)
	SELECT DISTINCT temp.CustID, temp.ReasonID
	FROM JSON_TABLE(ip_InputCustomers,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED		PATH "$.CustID"
			,	ReasonID		SMALLINT 			PATH "$.ReasonID"	
		 )) AS temp
	WHERE temp.ReasonID <> 0;
	
	CALL CTS_DC_ExcludeCustByCondition('Temp_InputCustomer');
    
	/*	2: GET EXISTED CUSTOMERS */
    INSERT IGNORE INTO Temp_ExistedCustomer(CustID,CTSCustID,IsLicensee,ReasonID)
    SELECT DISTINCT cust.CustID
        , 	cust.CTSCustID
        ,	(CASE WHEN m.SubscriberGroupID = 2 THEN 1 ELSE 0 END) AS IsLicensee
        ,	temp.ReasonID
    FROM Temp_InputCustomer AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.MappingSubscriberSite AS m ON cust.SiteID = m.SiteID;

    /*	3: IGNORE PIN CATEGORY	*/
    DELETE ec
    FROM Temp_ExistedCustomer AS ec
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = ec.CTSCustID; 
        
     /*	4: GET EVIDENCE	MAPPING RULE */
	INSERT IGNORE INTO Temp_EvidenceMapping(EvidenceID,EvidenceCode,IsLicensee,ReasonID)
    SELECT DISTINCT evd.EvidenceID
			,	evd.EvidenceCode
            ,	CASE WHEN evd.OrderNo <= 10 THEN 0 ELSE 1 END AS IsLicensee
            ,	rs.ReasonID
    FROM CTS_DataCenter.Evidence AS evd
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS etc ON etc.EvidenceID = evd.EvidenceID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = etc.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS rs ON rs.CategoryGroup = cat.CategoryGroup 
	WHERE (evd.OrderNo BETWEEN 1 AND 20) AND rs.ReasonID <> 0;
 
    /* 5: RETURN CUSTOMER EVIDENCE TO SYNC */
    SELECT DISTINCT ec.CTSCustID, ec.CustID, em.EvidenceID, em.EvidenceCode, 'Add from Problem Account Management' AS Remark 
    FROM Temp_ExistedCustomer AS ec 
		INNER JOIN Temp_EvidenceMapping AS em ON em.ReasonID = ec.ReasonID AND em.IsLicensee = ec.IsLicensee;
END$$
DELIMITER ;