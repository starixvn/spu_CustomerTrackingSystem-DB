/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedAccountMonitor_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedAccountMonitor_Insert`(
		IN ip_CTSCustIDs		TEXT
	,	IN ip_Remark			VARCHAR(200)
	,	IN ip_UserID			INT

	,	OUT op_ErrorMessage		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200706@Long.Luu
		Task:		Insert Associated Account Monitor [Redmine ID: #134652]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200706@Long.Luu: Created [Redmine ID: #134652]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: #148723] 
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
        
		Param's Explanation (filtered by):
	*/

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET @lv_CurrentDateTime	= NOW(); 
    SET @lv_SPName 		= 'CTS_DC_AssociatedAccountMonitor_Insert';
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustIDList;    
	CREATE TEMPORARY TABLE Temp_CTSCustIDList( 	  
		CTSCustID		BIGINT	 UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_CTSCustIDList (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
	INSERT IGNORE INTO CTS_DataCenter.AssociatedAccountMonitor(CTSCustID, Remark, CreatedBy, CreatedTime)
	SELECT  c.CTSCustID
		,	ip_Remark
        ,	ip_UserID
        ,	@lv_CurrentDateTime
	FROM Temp_CTSCustIDList AS c;
	
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(17, @lv_SPName, CONCAT('Add Associated Account Monitor: ip_CTSCustIDs_ ', ip_CTSCustIDs, ';Remark_', ip_Remark) , @lv_CurrentDateTime, ip_UserID);

END$$

DELIMITER ;