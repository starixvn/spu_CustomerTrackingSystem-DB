DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AssociatedAccountMonitor_Insert` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_AssociatedAccountMonitor_Insert` (
		IN ip_CTSCustIDs 		TEXT
	, 	IN ip_Remark			VARCHAR(200)
    ,	IN ip_UserID 			INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200))
BEGIN
	/*
		Created:	20200706@Long.Luu
		Task:		Insert Associated Account Monitor [Redmine ID: #134652]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200706@Long.Luu: Created [Redmine ID: #134652]
        
		Param's Explanation (filtered by):
	*/

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET @lv_CurrentDateTime	= NOW(); 
    SET @lv_SPName 		= 'CTS_DC_AssociatedAccountMonitor_Insert';
    
	DROP TEMPORARY TABLE IF EXISTS TmpCTSCustIDsList;    
	CREATE TEMPORARY TABLE TmpCTSCustIDsList
	( 	  
		CTSCustID		INT	 UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO TmpCTSCustIDsList (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
	INSERT IGNORE INTO CTS_DataCenter.AssociatedAccountMonitor(CTSCustID, Remark, CreatedBy, CreatedTime)
	SELECT  c.CTSCustID
		,	ip_Remark
        ,	ip_UserID
        ,	@lv_CurrentDateTime
	FROM TmpCTSCustIDsList AS c;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(17, @lv_SPName, CONCAT('Add Associated Account Monitor: ip_CTSCustIDs_ ', ip_CTSCustIDs, ';Remark_', ip_Remark) , @lv_CurrentDateTime, ip_UserID);
	
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;