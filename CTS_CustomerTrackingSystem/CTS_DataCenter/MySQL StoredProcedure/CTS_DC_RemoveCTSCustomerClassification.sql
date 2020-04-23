DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_RemoveCTSCustomerClassification`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_RemoveCTSCustomerClassification`(
		IN ip_CTSCustID			BIGINT UNSIGNED
	,	IN ip_CategoryID		SMALLINT
	,	IN ip_CreatedBy 		INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DELETE t
    FROM CTS_DataCenter.CTSCustomerClassification AS t
    WHERE t.CTSCustID = ip_CTSCustID
        AND t.CategoryID = ip_CategoryID;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(12, 'CTS_DC_RemoveCTSCustomerClassification', CONCAT('Delete CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_CategoryID_', ip_CategoryID,')'), CURRENT_TIME(), ip_CreatedBy);
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$	
DELIMITER ;