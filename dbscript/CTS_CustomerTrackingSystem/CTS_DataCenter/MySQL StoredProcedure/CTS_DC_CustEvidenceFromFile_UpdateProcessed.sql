/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceFromFile_UpdateProcessed`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceFromFile_UpdateProcessed`(
		IN ip_IDList			VARCHAR(2000)
	,	IN ip_UpdatedBy			INT
	,	OUT op_ErrorMessage		VARCHAR(200)
)
SQL SECURITY INVOKER

BEGIN
	/*
		Created:	20201106@Adam.Tran
		Task:		Update customer evidences [Redmine ID: 141563]
		DB:			CTS_DataCenter
		Original:

		Revisions:
		- 20201106@Adam.Tran [Redmine ID: 141563]: Created
	*/
	
	DECLARE lv_CurrentTime	TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidence;
	CREATE TEMPORARY TABLE Temp_CustomerEvidence
	(
		ID	BIGINT UNSIGNED		
		,	PRIMARY KEY		PK_Temp_CustomerEvidence_ID(ID) 
	);	
		
	SET @sql = CONCAT("INSERT INTO Temp_CustomerEvidence (ID) VALUES ('", REPLACE(ip_IDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;	
	
	UPDATE CTS_DataCenter.CustEvidenceFromFile AS ce
	INNER JOIN Temp_CustomerEvidence as temp
		ON temp.ID = ce.ID
	SET		ce.IsProcessed = 1
		,	ce.LastModifiedTime = lv_CurrentTime
		,	ce.LastModifiedBy = ip_UpdatedBy;		  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidence;
	
END$$

DELIMITER ;
