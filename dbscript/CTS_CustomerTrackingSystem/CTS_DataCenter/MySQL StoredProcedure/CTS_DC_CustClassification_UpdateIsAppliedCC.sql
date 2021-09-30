/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_UpdateIsAppliedCC`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_UpdateIsAppliedCC`(
		IN 	ip_ProcessedCustList 	JSON
    , 	OUT op_ErrorMessage 		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20201214@Irena.Vo
		Task:		Update IsAppliedCC = 1 from Customer List are updated CustomerClass in mainDB successfully (VVIP, Robot, Special CC, PA, Normal)
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20201214-20210107@Irena.Vo: Created. Update logic & Insert Error Log [RedmineID: #145951]
			- 20210625@Long.Luu: Refactor  [Redmine ID: #157203]
			- 20210920@Aries.Nguyen: Enhance performance  [Redmine ID: #161890]

		Param's Explanation (filtered by):		
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_UpdateIsAppliedCC('[{"CustId":"43600895","ScannedTime":"2020-10-02 00:00:00"}]', @op_ErrorMessage);
			
	*/ 
	DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200) DEFAULT '0';
    DECLARE lv_Stmp_Cond		LONGTEXT;
    DECLARE	lv_Stmp_Upd			LONGTEXT;
    DECLARE	lv_Stmp				LONGTEXT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(3, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_ProcessedCustList));
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProcessedCustList;    
	CREATE TEMPORARY TABLE Temp_ProcessedCustList 
    (	  
			CustID              BIGINT UNSIGNED 
        ,   ScannedTime         DATETIME
        ,   PRIMARY KEY 		PK_Temp_ProcessedCustList_CustID_ScannedTime(CustID,ScannedTime)
	);
    
    INSERT INTO Temp_ProcessedCustList(CustID, ScannedTime)
	SELECT DISTINCT 	temp.CustID
					, 	temp.ScannedTime
	FROM JSON_TABLE(ip_ProcessedCustList,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, ScannedTime		DATETIME		    PATH "$.ScannedTime"
		 )) AS temp;
	
    SELECT GROUP_CONCAT('(CustID = ',CustID, ' AND LastModifiedDate <= ', "'", ScannedTime, "')" SEPARATOR ' OR ')
	INTO lv_Stmp_Cond
	from Temp_ProcessedCustList;
    
    SET lv_Stmp_Upd = 'UPDATE CTS_DataCenter.CTSCustomerClassification_History 
					   SET IsAppliedCC = 1
					   WHERE  IsAppliedCC = 0 and SportGroupID in (200,0) and (';
                       
	SET @stmp = CONCAT(lv_Stmp_Upd, lv_Stmp_Cond, ');');
    
    PREPARE stmt FROM @stmp;
	EXECUTE stmt;
	
    DEALLOCATE PREPARE stmt;
END$$
DELIMITER ;