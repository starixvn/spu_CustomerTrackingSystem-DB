/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_UpdateSubsciberIDBySiteID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_UpdateSubsciberIDBySiteID`(
		IN ip_SubsSiteJson JSON
)
 SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200111@Casey.Huynh
		Task:		Update CTSCustomer
		DB:			CTS_DataCenter
		Original:

		Revisions:
			-	20210115@Casey.Huynh: Created [Redmine ID: 148849]
		Param's Explanation (filtered by):
		
  Exampele: CALL CTS_DC_CTSCustomer_UpdateInfoComplete(1000,500)
	*/
	
    DECLARE vl_size BIGINT DEFAULT 20;
    DECLARE vl_PreCTSCustID BIGINT DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS TempSubSite;
    
    CREATE TEMPORARY TABLE TempSubSite
    (
			SubscriberID	INT
        ,	SiteID			INT
        ,	RoleMapping		TINYINT
    );
    
    DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
    
    CREATE TEMPORARY TABLE TempCTSCustomer
    (
		CTSCustID	BIGINT UNSIGNED

        ,	PRIMARY KEY TempCTSCustomer(CTSCustID)
    );
      
	INSERT INTO TempSubSite(SubscriberID, SiteID, RoleMapping)
	SELECT		js.SubscriberID	
			,	js.SiteID
			,	js.RoleMapping
	FROM JSON_TABLE(ip_SubsSiteJson,
		 "$[*]" COLUMNS(
				SubscriberID	INT	 PATH "$.SubscriberID"
			,	SiteID			INT	 PATH "$.SiteID" 
            ,	RoleMapping		TINYINT	 PATH "$.RoleMapping" 
			)
	) AS js;

	WHILE (vl_PreCTSCustID IS NOT NULL)
    DO      
		SELECT vl_PreCTSCustID;
        TRUNCATE TABLE TempCTSCustomer;
		INSERT INTO TempCTSCustomer(CTSCustID)
        SELECT 		cus.CTSCustID
		FROM 		CTS_DataCenter.CTSCustomer AS cus 
        INNER JOIN	TempSubSite AS tmpSub
		WHERE 	cus.SubscriberID IS NULL
				AND cus.SiteID = tmpSub.SiteID
				AND cus.CTSCustID > vl_PreCTSCustID
		ORDER BY	cus.CTSCustID
		LIMIT		vl_size;
        
        UPDATE		CTS_DataCenter.CTSCustomer AS cus 
        INNER JOIN	TempCTSCustomer AS tmpCus ON cus.CTSCustID = tmpCus.CTSCustID
        INNER JOIN	TempSubSite AS mss 
					ON cus.SiteID = mss.SiteID 
					AND ((mss.RoleMapping = 1 AND cus.RoleID = 1)
						OR (mss.RoleMapping = 2 AND cus.RoleID > 1)
						OR (mss.RoleMapping = 0))
        SET			cus.SubscriberID = mss.SubscriberID;
        
        SET vl_PreCTSCustID = (SELECT MAX(tmpCus.CTSCustID) FROM TempCTSCustomer AS tmpCus);

    END WHILE;
END$$
DELIMITER ;