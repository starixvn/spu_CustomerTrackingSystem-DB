/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_UpdateCustInfoComplete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_UpdateCustInfoComplete`(
		IN ip_LastUpdateTime	DATETIME(3)
	,	IN ip_LastUpdateCustID	INT
	,	IN ip_CustInfo	JSON
)
 SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210208@Casey.Huynh
		Task:		Update CTSCustomer Info Complete
		DB:			CTS_DataCenter
		Original:

		Revisions:
			-	20210208@Casey.Huynh: Created [Redmine ID: 148849]
		Param's Explanation (filtered by):
		
		Example: 
	*/
	DECLARE     lv_No    INT    DEFAULT 1;
    DECLARE     lv_ErrorMessage2 VARCHAR(200) DEFAULT '';
    DECLARE		lv_ErrorMessage	VARCHAR(200) DEFAULT '';
 
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

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CTSCustomer_UpdateInfoComplete',lv_ErrorMessage, JSON_OBJECT('parameter', ip_CustInfo));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = lv_ErrorMessage;
    END;
 
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
	CREATE TEMPORARY TABLE TempCTSCustomer(
			CustID			INT UNSIGNED
        ,	CustStatusID	TINYINT
		,	Danger1			TINYINT
		,	Danger2			TINYINT
		,	Danger3			TINYINT
  
		,	INDEX IX_TempCTSCustomer_CustID(CustID)
	);	
 
	INSERT INTO TempCTSCustomer(CustID, CustStatusID, Danger1, Danger2, Danger3)
	SELECT	js.CustID
		,	js.CustStatusID
		,	js.Danger1		
		,	js.Danger2		
		,	js.Danger3
		
	FROM JSON_TABLE(ip_CustInfo, 
		"$[*]" COLUMNS(
				CustID			INT UNSIGNED	PATH "$.CustID"
            ,	CustStatusID	TINYINT	 		PATH "$.CustStatusID" 
			,	Danger1			TINYINT	 		PATH "$.Danger1" 
			,	Danger2			TINYINT	 		PATH "$.Danger2" 
			,	Danger3			TINYINT	 		PATH "$.Danger3"		
			
		)
	) AS js;	
       
	UPDATE 		CTS_DataCenter.CTSCustomer AS ctsCust
	INNER JOIN 	TempCTSCustomer AS tempCust ON ctsCust.CustID = tempCust.CustID
	SET		ctsCust.CustStatusID = tempCust.CustStatusID
		,	ctsCust.Danger1 = tempCust.Danger1
		,	ctsCust.Danger2 = tempCust.Danger2
		,	ctsCust.Danger3 = tempCust.Danger3
		,	ctsCust.ModifiedTime = NOW()
	WHERE	ctsCust.CustSubID = 0;
    
    #==================================================    	
	UPDATE	CTS_DataCenter.SystemParameter AS s
	SET		s.ParameterValue = ip_LastUpdateTime
	WHERE	s.ParameterID = 9 AND s.ParameterName = 'CTSCustomer_LastUpdateTimeCustInfo';
	
	UPDATE	CTS_DataCenter.SystemParameter AS s
	SET		s.ParameterValue = ip_LastUpdateCustID
	WHERE	s.ParameterID = 10 AND s.ParameterName = 'CTSCustomer_LastUpdateCustIDCustInfo';

END$$
DELIMITER ;