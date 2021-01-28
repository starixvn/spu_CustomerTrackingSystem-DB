/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_UpdateSubscriberIDBySiteID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_UpdateSubscriberIDBySiteID`(
		IN ip_SubsSiteJson JSON
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200111@Casey.Huynh
		Task:		Update CTSCustomer for SubscriberID NULL
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
        ,	UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SubscriberID	INT
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
		
        TRUNCATE TABLE TempCTSCustomer;
        
		INSERT INTO TempCTSCustomer(CTSCustID, RegisterName, SubscriberID, UserName)
        SELECT 		cus.CTSCustID
					,	cus.UserName
					,	SUBSTRING(cus.UserName2, LOCATE('$',cus.UserName2) + 1) AS RegisterName
                    ,	tmpSub.SubscriberID
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
        SET			cus.SubscriberID = mss.SubscriberID
					,	cus.RegisterName = tmpCus.RegisterName
					,	cus.ModifiedTime = NOW();
        
        SET vl_PreCTSCustID = (SELECT MAX(tmpCus.CTSCustID) FROM TempCTSCustomer AS tmpCus);
		
        #=====ReTransform==============================
		UPDATE		DCS_DataCenter.Account AS acc	
		INNER JOIN	TempCTSCustomer AS tmpCus
					ON acc.LoginName = tmpCus.RegisterName
					AND	acc.SubscriberID = tmpCus.SubscriberID
		SET			acc.IsCTSTransformed = 0
		WHERE		acc.IsCTSTransformed = -1;    
		
		UPDATE		DCS_DataCenter.Account AS acc	
		INNER JOIN	TempCTSCustomer AS tmpCus
					ON acc.LoginName = tmpCus.UserName
					AND acc.SubscriberID = tmpCus.SubscriberID
		SET			acc.IsCTSTransformed = 0
		WHERE		acc.IsCTSTransformed = -1;    
  
    END WHILE;
END$$
DELIMITER ;