DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RemoveSpecialCustomerClass $$

CREATE PROCEDURE CTS_DC_RemoveSpecialCustomerClass (
		IN ip_CTSCustID 		INT UNSIGNED
    ,	IN ip_UserID 			INT    
    
    , 	OUT op_ErrorMessage 	VARCHAR(200))
BEGIN
	/*
		Created:	20200908@Long.Luu
		Task:		Remove special customer class [Redmine ID: #140996]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200908@Long.Luu [Redmine ID: #140996]: Created 
        
		Param's Explanation (filtered by):
	*/
    DECLARE lv_CurrentDate DATETIME DEFAULT CURRENT_DATE();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_RemoveSpecialCustomerClass';
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
  
	DELETE	s
    FROM	CTS_DataCenter.SpecialCustomerClass AS s
    WHERE	s.CTSCustID = ip_CTSCustID;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(20, lv_SPName, CONCAT('Remove special customer class: ip_CTSCustID_ ', ip_CTSCustID) , lv_CurrentDate, ip_UserID);
	
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;