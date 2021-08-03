/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceQueue_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_Update`(
		IN 	ip_ProcessedIDList		VARCHAR(2000)
    
	,	OUT op_ErrorMessage			VARCHAR(200)
)
SQL SECURITY INVOKER
	
BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Update processed statsu for CustEvidenceQueue [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
		Param's Explanation (filtered by):   
			- ActionID: 1 insert, 2 override, 3 clear
		Example:			
			- call CTS_DataCenter.CTS_DC_CustEvidenceQueue_Update('1,2,3,4', @op_ErrorMessage);
	*/
	
	DECLARE lv_CurrentTime	TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_ProcessedID;
	CREATE TEMPORARY TABLE Temp_ProcessedID
	(
		ID	BIGINT UNSIGNED	PRIMARY KEY
	);	
		
	SET @sql = CONCAT("INSERT INTO Temp_ProcessedID (ID) VALUES ('", REPLACE(ip_ProcessedIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;	
	
	UPDATE CTS_DataCenter.CustEvidenceQueue AS ce
		INNER JOIN Temp_ProcessedID AS t ON t.ID = ce.ID
	SET		ce.IsProcessed = 1
		,	ce.LastModifiedTime = lv_CurrentTime;		  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProcessedID;
END$$
DELIMITER ;