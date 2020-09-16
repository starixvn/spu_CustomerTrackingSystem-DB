DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Remove $$

CREATE PROCEDURE CTS_DC_AssociatedAccountMonitor_Remove (
		IN ip_CTSCustID 		INT UNSIGNED
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
    
    SET @lv_CurrentDate 	= CURRENT_DATE();    
    SET @lv_SPName 			= 'CTS_DC_AssociatedAccountMonitor_Remove';
    
	DELETE	a
    FROM	CTS_DataCenter.AssociatedAccountMonitor AS a
    WHERE	a.CTSCustID = ip_CTSCustID;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(18, @lv_SPName, CONCAT('Remove Associated Account Monitor: ip_CTSCustID_ ', ip_CTSCustID) , @lv_CurrentDate, ip_UserID);
	
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;