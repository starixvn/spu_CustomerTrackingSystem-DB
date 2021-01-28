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
			-	20210115@Casey.Huynh: Created [Redmine ID: 148849]
		Param's Explanation (filtered by):
        30	130	1284	0	305RM		
        CALL CTS_DataCenterCTS_DC_CTSCustomer_InsertComplete ('[{"CTSCustId":30, "CustID:"1284,"Username":"305RM","RegisterName":null,"SubscriberID":130}]'))
	*/
    DECLARE lv_LastInsertCustID INT;
    DECLARE lv_LastInsertCustSubID INT;    
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

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CTSCustomer_InsertComplete',lv_ErrorMessage, JSON_OBJECT('parameter', ip_Customer));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = lv_ErrorMessage;
    END;
    
   DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
    
	CREATE TEMPORARY TABLE Temp_CTSCustomer
	( 		CTSCustID		BIGINT UNSIGNED NOT NULL
		, 	CustID			BIGINT
        ,	CustSubID		BIGINT
		,	UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SubscriberID	INT
        
        ,	INDEX IX_Temp_CTSCustomer_CustID(CustID)
        ,	INDEX IX_Temp_CTSCustomer_CustSubID(CustSubID)
    );
    
    INSERT INTO Temp_CTSCustomer
	SELECT		js.CTSCustID
			, 	js.CustID
			,	js.CustSubID
			,	js.UserName
            ,	js.RegisterName
            ,	js.SubscriberID
	FROM JSON_TABLE(ip_Customer,
		 "$[*]" COLUMNS(
				CTSCustID		BIGINT	UNSIGNED	PATH "$.CTSCustID" 
			, 	CustID			BIGINT UNSIGNED		PATH "$.CustID"  
			,	CustSubID		BIGINT UNSIGNED		PATH "$.CustSubID"  
			,	UserName		VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.UserName"
			,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.RegisterName"
            ,	SubscriberID	INT	PATH "$.SubscriberID" 
			)
	) AS js;
    
    
   #=====ReTransform==============================
    UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	Temp_CTSCustomer AS tmpCus
				ON acc.LoginName = tmpCus.RegisterName
				AND	acc.SubscriberID = tmpCus.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1;    
    
	UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	Temp_CTSCustomer AS tmpCus
				ON acc.LoginName = tmpCus.UserName
                AND acc.SubscriberID = tmpCus.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1;    
  
    #=====Update Scan System Parameter;
    SET lv_LastInsertCustID = (SELECT MAX(tmpCus.CustID) FROM Temp_CTSCustomer AS tmpCus WHERE CustSubID = 0);
    IF lv_LastInsertCustID > 0
    THEN
		UPDATE 	CTS_DataCenter.SystemParameter AS s
        SET		s.ParameterValue = lv_LastInsertCustID
		WHERE	s.ParameterID = 7 AND s.ParameterName = 'CTSCustomer_LastInsertCustID';
	END IF;
    
	SET lv_LastInsertCustSubID = (SELECT MAX(tmpCus.CustSubID) FROM Temp_CTSCustomer AS tmpCus);
    IF lv_LastInsertCustSubID > 0
    THEN
		UPDATE 	CTS_DataCenter.SystemParameter AS s
        SET		s.ParameterValue = lv_LastInsertCustSubID
		WHERE	s.ParameterID = 8 AND s.ParameterName = 'CTSCustomer_LastInsertCustSubID';
	END IF;
END$$
DELIMITER ;