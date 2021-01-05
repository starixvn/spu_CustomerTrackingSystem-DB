/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_UpdateLastScanDate`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_UpdateLastScanDate`(IN ip_CustSport json, OUT op_ErrorMessage VARCHAR(200))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Update Last Scanned for probation customer if it run completely
		DB:			CTS_DataCenter
        
		Original:
		Revisions:
			- [20201116@Irena.Vo][145028]: Add column LastScannedDate & Enhance logic
	        - 20210105@Irena.Vo: Created. Insert Error Log [RedmineID: #145951]
            
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/
    DECLARE lv_CurrentDateTime  DATETIME DEFAULT CURRENT_TIME();
    
    DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			VARCHAR(200)  DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS @op_No = NUMBER;
		GET DIAGNOSTICS CONDITION @op_No 
			op_ErrorNo 			= 	MYSQL_ERRNO
        ,	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description, CreatedDate)
        VALUES(2, op_ErrorMessage, JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_CustSport),lv_CurrentDateTime);
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport 
    (	  
		  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED        
        , INDEX				IX_Temp_CustSport_CTSCustID(CustID, SportGroupID)    
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID) 
	SELECT 		DISTINCT temp.CustID, temp.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) AS temp;
    
    UPDATE 		CTS_DataCenter.ProbationAccountMonitor AS pro
    INNER JOIN 	Temp_CustSport AS temp ON pro.CustID = temp.CustID AND pro.SportGroupID = temp.SportGroupID
    SET			pro.LastScannedDate = DATE(lv_CurrentDateTime);
    
END$$

DELIMITER ;

