/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_InsertComplete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_InsertComplete`(IN ip_Customer JSON)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210115@Casey.Huynh
		Task:		Insert Customer Complte [Redmine ID: 148849]. Re-Transfrom DCS Account and update LastInsertedCustID, LastInsertedCustSubID System Parameter
		DB:			CTS_DataCenter
		Original:

		Revisions:
			
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenterCTS_DC_CTSCustomer_InsertComplete ('[{"CustId":1,"Username":"SA-SD$","RegisterName":null,"Site":"BEST-ODDS","SubscriberID":1}]'))
	*/
    DECLARE lv_LastInsertCustID INT;
    DECLARE lv_LastInsertCustSubID INT;
    
   DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
    
	CREATE TEMPORARY TABLE TempCTSCustomer
	( 		CTSCustID		INT UNSIGNED NOT NULL
		,	UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SubscriberID	INT
    );
    
    INSERT INTO TempCTSCustomer
	SELECT		js.CTSCustID	
			,	js.UserName
            ,	js.RegisterName
            ,	js.SubscriberID
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CTSCustID		INT	 UNSIGNED	PATH "$.CTSCustID" 
			,	UserName		VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.Username"
			,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.RegisterName"
            ,	SubscriberID	INT 			PATH "$.SubscriberID" 
			)
	) AS js;
    
    
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
  
    #=====Update Scan System Parameter;
    SET lv_LastInsertCustID = (SELECT MAX(tmpCus.CustID) FROM TempItemTable AS tmpCus);
    IF lv_LastInsertCustID > 0
    THEN
		UPDATE 	CTS_DataCenter.SystemParameter AS s
        SET		s.ParamaterValue = lv_LastInsertCustID
		WHERE	s.ParameterID = 7 AND s.ParameterName = 'CTSCustomer_LastInsertCustID';
	END IF;
    
	SET lv_LastInsertCustSubID = (SELECT MAX(tmpCus.CustSubID) FROM TempItemTable AS tmpCus);
    IF lv_LastInsertCustSubID > 0
    THEN
		UPDATE 	CTS_DataCenter.SystemParameter AS s
        SET		s.ParamaterValue = lv_LastInsertCustSubID
		WHERE	s.ParameterID = 8 AND s.ParameterName = 'CTSCustomer_LastInsertCustSubID';
	END IF;
END$$
DELIMITER ;