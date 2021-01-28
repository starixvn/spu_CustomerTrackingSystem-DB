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
		
  Exampele: CALL CTS_DC_CTSCustomer_UpdateSubscriberIDBySiteID ('[{"SubscriberID":898294,"SiteID":43534235,"RoleMapping":1}]');
	*/
	
    DECLARE lv_size BIGINT DEFAULT 200;
    DECLARE lv_PreCTSCustID BIGINT DEFAULT 0;
	DECLARE lv_No    INT    DEFAULT 1;
    DECLARE lv_ErrorMessage2 VARCHAR(200) DEFAULT '';
    DECLARE	lv_ErrorMessage	VARCHAR(200) DEFAULT '';
 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No = NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            lv_ErrorMessage = MESSAGE_TEXT;	
		
		IF(lv_No > 1) THEN
			SET lv_No = lv_No - 1;
			GET STACKED  DIAGNOSTICS CONDITION lv_No
				lv_ErrorMessage2 = MESSAGE_TEXT;	
        END IF;
			
		SET lv_ErrorMessage = CONCAT(lv_ErrorMessage,'; ',lv_ErrorMessage2);

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CTSCustomer_Insert',lv_ErrorMessage, JSON_OBJECT('parameter', ip_CustomerList));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = lv_ErrorMessage;
    END;
    
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

	WHILE (lv_PreCTSCustID IS NOT NULL)
    DO      
		
        TRUNCATE TABLE TempCTSCustomer;
        
		INSERT INTO TempCTSCustomer(CTSCustID, RegisterName, SubscriberID, UserName)
        SELECT 		cus.CTSCustID					
					,	SUBSTRING(cus.UserName2, LOCATE('$',cus.UserName2) + 1) AS RegisterName
                    ,	mss.SubscriberID
                    ,	cus.UserName
		FROM 		CTS_DataCenter.CTSCustomer AS cus 
		INNER JOIN	TempSubSite AS mss ON cus.SiteID = mss.SiteID 
				AND ((mss.RoleMapping = 1 AND cus.RoleID = 1)
					OR (mss.RoleMapping = 2 AND cus.RoleID > 1)
					OR (mss.RoleMapping = 0))
		WHERE 	cus.SubscriberID IS NULL
				AND cus.SiteID = mss.SiteID
				AND cus.CTSCustID > lv_PreCTSCustID
		ORDER BY	cus.CTSCustID
		LIMIT		lv_size;
        
        UPDATE		CTS_DataCenter.CTSCustomer AS cus 
        INNER JOIN	TempCTSCustomer AS tmpCus ON cus.CTSCustID = tmpCus.CTSCustID
        SET			cus.SubscriberID = tmpCus.SubscriberID
					,	cus.RegisterName = tmpCus.RegisterName
					,	cus.ModifiedTime = NOW();
        
        SET lv_PreCTSCustID = (SELECT MAX(tmpCus.CTSCustID) FROM TempCTSCustomer AS tmpCus);
		
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