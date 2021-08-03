/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_ProbationScan_UpdateScanDate`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ProbationScan_UpdateScanDate`(
        IN ip_CustSport JSON

    ,   OUT op_ErrorMessage VARCHAR(200)
)
    SQL SECURITY INVOKER 
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Update Last Scanned for probation customer if it run completely
		DB:			CTS_DataCenter
        
		Original:
		Revisions:
			- [20201116@Irena.Vo][145028]: Add column LastScannedDate & Enhance logic
	        - 20210107@Irena.Vo: Insert Error Log [RedmineID: #145951]
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
            
		Param's Explanation (filtered by):
            -ip_CategoryIDList: ex: '1,2,3'       
	*/
	DECLARE	lv_No				INT				DEFAULT 0;
    DECLARE lv_ErrorNo 			INT 			DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200)  	DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
        	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(2, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_CustSport));
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport (	  
		    CustID			    BIGINT UNSIGNED        
        ,   SportGroupID		SMALLINT UNSIGNED        
        ,   INDEX				IX_Temp_CustSport_CTSCustID(CustID, SportGroupID)    
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID) 
	SELECT 		DISTINCT temp.CustID, temp.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) AS temp;
    
    UPDATE      CTS_DataCenter.ProbationAccountMonitor AS pro
        INNER JOIN 	Temp_CustSport AS temp ON pro.CustID = temp.CustID AND pro.SportGroupID = temp.SportGroupID
    SET         pro.LastScannedDate = CURRENT_DATE();
    
END$$
DELIMITER ;