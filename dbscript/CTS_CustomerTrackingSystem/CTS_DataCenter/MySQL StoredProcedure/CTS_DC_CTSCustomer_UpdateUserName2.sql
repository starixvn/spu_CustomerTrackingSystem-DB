DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CTSCustomer_UpdateUserName2 $$

CREATE PROCEDURE `CTS_DC_CTSCustomer_UpdateUserName2`(IN ip_Size INT, IN ip_Customer JSON)
BEGIN
	/*
		Created:	20200118@CaseyHuynh
		Task:		GET CTSCustID NULL
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200421@Harvey:	Get customer for update SubscriberID - [Redmine: #132705]
        
		Param's Explanation (filtered by):         
        
        CALL CTS_DC_GetCustomerForUpdateUsername2 (500,0,1)
	*/	  
	
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
    
	CREATE TEMPORARY TABLE TempCTSCustomer
	( 		CustID			INT UNSIGNED NOT NULL
		,	CustSubID		BIGINT
		,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SubscriberID	INT
    );
    
    INSERT INTO TempCTSCustomer
	SELECT		js.CustID	
			,	js.CustSubID		
			,	(CASE WHEN js.UserName2 = 'null' THEN NULL ELSE js.UserName2 END) AS UserName2
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CustID			INT	 UNSIGNED	PATH "$.CustId" 
			,	CustSubID		BIGINT			PATH "$.CustSubId"
			,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.Username2" 
			)
	) AS js;
    
    UPDATE 		TempCTSCustomer AS tmpCus
	INNER JOIN	CTS_DataCenter.MappingSubscriberSite mss 
				ON tmpCus.SiteID = mss.SiteID 
				AND ((mss.RoleMapping = 1 AND tmpCus.RoleID = 1)
					OR (mss.RoleMapping = 2 AND tmpCus.RoleID > 1)
					OR (mss.RoleMapping = 0))
	SET 		tmpCus.SubscriberID = mss.SubscriberID
				, tmpCus.RegisterName = SUBSTRING(tmpCus.UserName2, LOCATE('$',tmpCus.UserName2) + 1);
	
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
END$$
DELIMITER ;
