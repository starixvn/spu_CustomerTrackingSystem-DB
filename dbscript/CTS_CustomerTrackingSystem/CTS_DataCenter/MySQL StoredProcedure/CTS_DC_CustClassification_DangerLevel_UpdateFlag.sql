/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DangerLevel_UpdateFlag`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_DangerLevel_UpdateFlag`(
		IN ip_ProcessedCustList JSON
    , 	IN ip_TypeID 			SMALLINT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20210401@Irena.Vo
		Task:		Update IsAppliedDangerlevel from Customer List are updated Danger level in mainDB successfully
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20210401@Irena.Vo: Create [RedmineID: #152249] 
		
		Param's Explanation (filtered by):		
			ip_ProcessedCustList ; ip_TypeID: 1(Original) / 2(ABI) / 3(Other)
			call CTS_DataCenter.CTS_DC_CustClassification_DangerLevel_UpdateFlag('[{"CustId":"2324948","ScannedTime":"2021-03-08 04:04:48"},{"CustId":"36266996","ScannedTime":"2021-03-08 04:13:38"}]', 1);
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

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CustClassification_DangerLevel_UpdateFlag',lv_ErrorMessage, JSON_OBJECT('parameter', ip_ProcessedCustList));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = lv_ErrorMessage;
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProcessedCustList;    
	CREATE TEMPORARY TABLE Temp_ProcessedCustList 
    (	  
			CustID              BIGINT UNSIGNED 
        ,   ScannedTime         DATETIME
        ,   PRIMARY KEY 		PK_Temp_ProcessedCustList_CustID_ScannedTime(CustID,ScannedTime)
        , 	INDEX 				IX_Temp_ProcessedCustList_ScannedTime(ScannedTime)       
     );
    
    INSERT INTO Temp_ProcessedCustList(CustID, ScannedTime)
	SELECT DISTINCT 	temp.CustID
					, 	temp.ScannedTime
	FROM JSON_TABLE(ip_ProcessedCustList,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, ScannedTime		DATETIME		    PATH "$.ScannedTime"
		 )) AS temp;
    
    IF (ip_TypeID = 1) THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate <= temp.ScannedTime AND his.IsAppliedDangerLevel1 = 0 
		SET his.IsAppliedDangerLevel1 = 1;
	END IF;
	/* IF (ip_TypeID = 2) THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate <= temp.ScannedTime AND his.IsAppliedDangerLevel2 = 0 
		SET his.IsAppliedDangerLevel2 = 1;
	END IF;
	IF (ip_TypeID = 3) THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProcessedCustList AS temp ON temp.CustID = his.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate <= temp.ScannedTime AND his.IsAppliedDangerLevel3 = 0 
		SET his.IsAppliedDangerLevel3 = 1;
	END IF; */
END$$
DELIMITER ;