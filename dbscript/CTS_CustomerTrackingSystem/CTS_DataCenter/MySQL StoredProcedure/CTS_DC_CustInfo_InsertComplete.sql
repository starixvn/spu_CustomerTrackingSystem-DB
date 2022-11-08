/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_InsertComplete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_InsertComplete`(
		IN ip_LastInsertCustID  BIGINT UNSIGNED
	,	IN ip_Customer			JSON
    ,	IN ip_IsInsertMissing	BOOLEAN
    , 	IN ip_LogFlow VARCHAR(100)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210115@Casey.Huynh
		Task:		Insert Customer Complte [Redmine ID: 148849]. Re-Transfrom DCS Account and update LastInsertedCustID, LastInsertedCustSubID System Parameter
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210115@Casey.Huynh: Created [Redmine ID: 148849]
            - 20210506@Casey.Huynh: LastCustID is sent from MainDB. Add Input Parameter ip_LastCustID [Redmine ID: 154633]
			- 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]
			- 20211220@Harvey.Nguyen: Add ip_IsInsertMissing for insert missing customer [Redmine ID: #166173]
            - 20221107@Casey.Huynh: Log DCSAccount Transform to CTS  [Redmine ID: #180182]

		Param's Explanation (filtered by):
        
		Example:
			- CALL CTS_DataCenterCTS_DC_CTSCustomer_InsertComplete (10,'[{"CTSCustId":30, "CustID:"1284,"Username":"305RM","RegisterName":null,"SubscriberID":130}]'))
	*/
    DECLARE lv_LastInsertCustID INT;
    DECLARE lv_LastInsertCustSubID INT;   
    
	DECLARE lv_Log_MaxID BIGINT UNSIGNED;   
    
    /*LOG: Start*/
    INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText, JsonString1)
    SELECT 'CTS_DC_CustInfo_InsertComplete',CURRENT_TIMESTAMP(4), CONCAT(', ip_LogFlow:',IFNULL(ip_LogFlow,'Unknow'), 'ip_LastInsertCustID:',ip_LastInsertCustID,', ip_IsInsertMissing:',ip_IsInsertMissing), ip_Customer;
    /*LOG: END*/  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;    
	CREATE TEMPORARY TABLE Temp_CTSCustomer( 		
			CTSCustID		BIGINT UNSIGNED NOT NULL
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
    #LOG: Start
		SELECT IFNULL(MAX(ID),0) INTO lv_Log_MaxID FROM DCS_DataCenter.AccountTransformStatus;        
    #LOG: END
    
	INSERT INTO DCS_DataCenter.AccountTransformStatus(AccountID, IsCTSTransformed)
	SELECT	acc.AccountID
		,	0
	FROM  DCS_DataCenter.Account AS acc
		INNER JOIN	Temp_CTSCustomer AS tmpCus ON acc.LoginName = tmpCus.RegisterName AND	acc.SubscriberID = tmpCus.SubscriberID
	WHERE acc.IsCTSTransformed = -1; 
    
    INSERT INTO DCS_DataCenter.AccountTransformStatus(AccountID, IsCTSTransformed)
	SELECT	acc.AccountID
		,	0
	FROM  DCS_DataCenter.Account AS acc
		INNER JOIN	Temp_CTSCustomer AS tmpCus ON acc.LoginName = tmpCus.UserName AND acc.SubscriberID = tmpCus.SubscriberID
	WHERE acc.IsCTSTransformed = -1; 
	   
    IF NOT ip_IsInsertMissing
    THEN 
		#=====Update Scan System Parameter;
		IF ip_LastInsertCustID > 0
		THEN
			UPDATE 	CTS_DataCenter.SystemParameter AS s
			SET		s.ParameterValue = ip_LastInsertCustID
			WHERE	s.ParameterID = 7 ; # s.ParameterName = 'CTSCustomer_LastInsertCustID';
		END IF;
		
		SET lv_LastInsertCustSubID = (SELECT MAX(tmpCus.CustSubID) FROM Temp_CTSCustomer AS tmpCus);
		IF lv_LastInsertCustSubID > 0
		THEN
			UPDATE 	CTS_DataCenter.SystemParameter AS s
			SET		s.ParameterValue = lv_LastInsertCustSubID
			WHERE	s.ParameterID = 8; # s.ParameterName = 'CTSCustomer_LastInsertCustSubID';
		END IF;
    END IF;

    #LOG: Start
		INSERT IGNORE INTO CTS_Log.AccountTransformStatus_Log(ID, AccountID, IsCTSTransformed) 
        SELECT ID, AccountID, IsCTSTransformed FROM DCS_DataCenter.AccountTransformStatus 
        WHERE ID > lv_Log_MaxID;    
    #LOG: END

END$$
DELIMITER ;