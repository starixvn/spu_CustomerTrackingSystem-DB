DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RemoveException$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_RemoveException(IN ip_UserID BIGINT, IN ip_FromCTSCustID BIGINT, IN ip_ToUserName VARCHAR(50), IN ip_Comment VARCHAR(200), OUT op_Error TINYINT)
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Add Exception
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
	*/ 
 
    DECLARE		vr_ToCTSCustID 	BIGINT;
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_RemoveException';
    
    SET vr_ToCTSCustID = (SELECT CTSCustID FROM CTS_DataCenter.CTSCustomer AS ct WHERE ct.UserName = ip_ToUserName OR ct.UserName = ip_ToUserName2);
   
    IF(vr_ToCTSCustID IS NULL) THEN
		 SET	op_Error = 1;
	ELSE
		SET	vr_CreatedDate = CURRENT_DATE();
        
        #======REMOVE EXCEPTION=================================
        DELETE 
        FROM	 CTS_DataCenter.CustException AS ce
        WHERE	(ce.FromCTSCustID = ip_FromCTSCustID 	AND ce.ToCTSCustID = vr_ToCTSCustID)
				OR (ce.FromCTSCustID = vr_ToCTSCustID 	AND ce.ToCTSCustID = ip_FromCTSCustID);	 	
                
		INSERT INTO CTS_Admin.UserLog(SPName, LogInfo, CreatedDate, CreatedBy)
        VALUES(vr_LogSPName, 'Remove Exception', vr_CreatedDate, ip_UserID);
        
        #=====ADD AFFECTED EVIDENCE==========================
        DELETE 	ce
        FROM 	CTS_DataCenter.CustEvidence AS ce
        WHERE	(ce.CTSCustID = ip_FromCTSCustID AND ce.FromCustID = vr_ToCTSCustID)
				OR (ce.CTSCustID = ip_FromCTSCustID AND ce.FromCustID = vr_ToCTSCustID);
        
		INSERT INTO CTS_Admin.UserLog(SPName, LogInfo, CreatedDate, CreatedBy)
        VALUES(vr_LogSPName, 'Remove Affected Exception', vr_CreatedDate, ip_UserID);
        
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    SET	op_Error = 0;    
    END IF;
END$$	
DELIMITER ;