/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CTSCustomer_UpdateUserName2 $$

CREATE PROCEDURE CTS_DC_CTSCustomer_UpdateUserName2(IN ip_Customer JSON)
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
		,	CustSubID		INT
        ,	CTSCustID		BIGINT
		,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SubscriberID	INT
    );
    
    INSERT INTO TempCTSCustomer(CustID, CustSubID, UserName2, CTSCustID)
	SELECT		js.CustID	
			,	js.CustSubID            
			,	(CASE WHEN js.UserName2 = 'null' THEN NULL ELSE js.UserName2 END) AS UserName2
            ,	js.CTSCustID
	FROM JSON_TABLE(ip_Customer,
		 "$[*]" COLUMNS(
				CustID			INT	 UNSIGNED	PATH "$.CustID" 
			,	CustSubID		BIGINT			PATH "$.CustSubID"
			,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.UserName2" 
            ,	CTSCustID		BIGINT			PATH "$.CTSCustID"
			)
	) AS js;    
   
    UPDATE 		TempCTSCustomer AS tmpCus
    INNER JOIN 	CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmpCus.CTSCustID 
	INNER JOIN	CTS_DataCenter.MappingSubscriberSite mss 
				ON cus.SiteID = mss.SiteID 
				AND ((mss.RoleMapping = 1 AND cus.RoleID = 1)
					OR (mss.RoleMapping = 2 AND cus.RoleID > 1)
					OR (mss.RoleMapping = 0))
	SET 		tmpCus.SubscriberID = cus.SubscriberID
				, tmpCus.RegisterName = SUBSTRING(tmpCus.UserName2, LOCATE('$',tmpCus.UserName2) + 1);       
   
	UPDATE		CTS_DataCenter.CTSCustomer AS cus
    INNER JOIN	CTS_DataCenter.TempCTSCustomer AS tmpCus ON cus.CTSCustID = tmpCus.CTSCustID 
    SET			cus.UserName2 = tmpCus.UserName2
				, cus.RegisterName = tmpCus.RegisterName;

   #=====ReTransform==============================
    UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	TempCTSCustomer AS tmpCus
				ON acc.LoginName = tmpCus.RegisterName
				AND	acc.SubscriberID = tmpCus.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1;    

END$$
DELIMITER ;
