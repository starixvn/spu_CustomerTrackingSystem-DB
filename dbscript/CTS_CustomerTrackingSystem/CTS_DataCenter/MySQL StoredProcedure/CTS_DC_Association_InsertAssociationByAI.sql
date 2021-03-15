DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_Association_InsertAssociationByAI`$$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_Association_InsertAssociationByAI`(
	IN 	ip_DailyStats 		JSON,
	IN 	ip_ScanDate			DATETIME,
    
    OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210217@Long.Luu
		Task:		Insert Association By AI [Redmine ID: #0000]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20210217@Long.Luu: Created [Redmine ID: #0000]
            
		Example:
			call CTS_DataCenter.CTS_DC_Association_InsertAssociationByAI ('[{"C1": 43600693, "C2": 45}]', '2021-01-11', @ErrorMessage);    
	*/ 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	INSERT IGNORE INTO CTS_DataCenter.AssociationByAI(FromCustID, ToCustID, CreatedDate)
	SELECT 	tmpTable.CustID1
		, 	tmpTable.CustID2
        ,	ip_ScanDate
	FROM JSON_TABLE(ip_DailyStats,
		 "$[*]" COLUMNS(
			  CustID1 		BIGINT UNSIGNED		PATH "$.C1"
			, CustID2		BIGINT UNSIGNED		PATH "$.C2"
		 )) AS tmpTable;  
     
END$$	
DELIMITER ;