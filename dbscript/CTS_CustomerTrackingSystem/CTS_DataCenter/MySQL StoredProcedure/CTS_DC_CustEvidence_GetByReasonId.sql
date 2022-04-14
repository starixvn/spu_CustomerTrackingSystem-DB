/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsService,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustEvidence_GetByReasonId`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetByReasonId`(
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
	DROP TEMPORARY TABLE IF EXISTS Temp_CustParam;    
	CREATE TEMPORARY TABLE Temp_CustParam( 	  
			CustID			BIGINT UNSIGNED
        , 	CTSCustID		BIGINT UNSIGNED
        ,	EvidenceID		INT 
        ,   EvidenceCode	VARCHAR(10)
        ,   PRIMARY KEY(CTSCustID,EvidenceID)
	);
	
	/*	2: GET EXISTED CUSTOMERS */
    INSERT IGNORE INTO Temp_CustParam(CustID,CTSCustID,EvidenceID,EvidenceCode)
	SELECT	info.CustID
		,	cust.CTSCustID
        ,	ev.EvidenceID
        ,	ev.EvidenceCode
	FROM JSON_TABLE(ip_InputCustomers,
		 "$[*]" COLUMNS(
				CustID			VARCHAR(50)		PATH "$.CustID" 
			, 	ReasonID		INT				PATH "$.ReasonID")
	) AS info
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON info.CustID = cust.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.MappingSubscriberSite AS m ON cust.SiteID = m.SiteID,
        LATERAL (SELECT  CASE WHEN m.SubscriberGroupID = 2  THEN cate.EvidenceID_Licensee ELSE cate.EvidenceID_Credit END AS EvidenceID
					,	 CASE WHEN m.SubscriberGroupID = 2  THEN cate.EvidenceCode_Licensee ELSE cate.EvidenceCode_Credit END AS EvidenceCode
                 FROM CTS_DataCenter.CustomerCategory AS cate
                 WHERE cate.ReasonID = info.ReasonID 
					AND (cate.EvidenceID_Licensee IS NOT NULL OR  cate.EvidenceCode_Credit  IS NOT NULL)
                 LIMIT 1) AS ev;
    
    CALL CTS_DC_ExcludeCustByCondition('Temp_CustParam');
    
    DELETE ec
    FROM Temp_CustParam AS ec
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = ec.CTSCustID; 
        
    /* 5: RETURN CUSTOMER EVIDENCE TO SYNC */
    SELECT 	DISTINCT 
			ec.CTSCustID
		, 	ec.CustID
		, 	ec.EvidenceID
        , 	ec.EvidenceCode
        , 	'Add from Problem Account Management' AS Remark 
    FROM Temp_CustParam AS ec ;
END$$
DELIMITER ;