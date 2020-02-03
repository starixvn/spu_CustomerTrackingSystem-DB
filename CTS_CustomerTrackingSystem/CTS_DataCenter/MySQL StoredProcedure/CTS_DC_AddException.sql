DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AddException$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_AddException(IN ip_UserID BIGINT, IN ip_FromCTSCustID BIGINT, IN ip_ToUserName VARCHAR(50), IN ip_Comment VARCHAR(200), OUT op_Error TINYINT)
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Add Exception
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
			OutPut: op_Error (1: User Is not Existing, 0: Add Successfully)
	*/ 
 
    DECLARE		vr_ToCTSCustID 	BIGINT;
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_AddException';
    
    
    SET vr_ToCTSCustID = (SELECT CTSCustID FROM CTS_DataCenter.CTSCustomer AS ct WHERE ct.UserName = ip_ToUserName OR ct.UserName = ip_ToUserName2);
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    IF(vr_ToCTSCustID IS NULL) THEN
		 SET	op_Error = 1;
	ELSE
		SET	vr_CreatedDate = CURRENT_DATE();
        
        #======INSERT EXCEPTION=================================
		INSERT INTO CTS_DataCenter.CustException(FromCTSCustID, ToCTSCustID, CreatedDate, CreatedBy, Comment)
        VALUES(ip_FromCTSCustID, vr_ToCTSCustID, vr_CreatedDate , ip_UserID, ip_Comment);
        
        INSERT INTO CTS_Admin.UserLog(SPName, LogInfo, CreatedDate, CreatedBy)
        VALUES(vr_LogSPName, 'Insert Exception' , vr_CreatedDate, ip_UserID);
        
        #=====REMOVE AFFECTED EVIDENCE==========================
        DELETE 	ce
        FROM 	CTS_DataCenter.CustEvidence AS ce
        WHERE	(ce.CTSCustID = ip_FromCTSCustID AND ce.FromCustID = vr_ToCTSCustID)
				OR (ce.CTSCustID = ip_FromCTSCustID AND ce.FromCustID = vr_ToCTSCustID);
        
		INSERT INTO CTS_Admin.UserLog(SPName, LogInfo, CreatedDate, CreatedBy)
        VALUES(vr_LogSPName, 'Remove Affected Exception', vr_CreatedDate, ip_UserID);
        
        

    SET	op_Error = 0;    
    END IF;
END$$	
DELIMITER ;