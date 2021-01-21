/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_InsertException`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_InsertException`(IN ip_UserID int,IN ip_FromCTSCustID bigint,IN ip_ToUserName varchar(50),IN ip_Comment varchar(500),OUT op_Error int)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Add Exception
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200807@Casey.Huynh:[138925]: Change ip_Comment VARCHAR(200) To ip_Comment VARCHAR(500)
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			
		Param's Explanation (filtered by):
			OutPut: vr_Error (1: User Is not Existing, 0: Add Successfully)
	*/ 
 
    DECLARE		vr_ToCTSCustID 	BIGINT;
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 		VARCHAR(100) 	DEFAULT 'CTS_DC_Association_InsertException';
    DECLARE		vr_Error		INT DEFAULT 0;

    SET SESSION default_collation_for_utf8mb4 = utf8mb4_0900_ai_ci;
    
    SET vr_ToCTSCustID = (	SELECT	CTSCustID 
							FROM	CTS_DataCenter.CTSCustomer AS ct 
                            WHERE	ct.UserName 	= ip_ToUserName 
									OR ct.UserName2 = ip_ToUserName);    
    
    IF(vr_ToCTSCustID IS NULL) THEN
		 SET	vr_Error = 1;
	ELSE
		SET	vr_CreatedDate = CURRENT_TIME();
        
        #======INSERT EXCEPTION=================================
		INSERT INTO CTS_DataCenter.CustException(FromCTSCustID, ToCTSCustID, CreatedDate, CreatedBy, Comment)
        VALUES(ip_FromCTSCustID, vr_ToCTSCustID, vr_CreatedDate , ip_UserID, ip_Comment);
 
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(1,vr_SPName, CONCAT('Insert Exception: ip_FromCTSCustID_', ip_FromCTSCustID, ';ip_ToUserName_', ip_ToUserName,'(',vr_ToCTSCustID,')'), vr_CreatedDate, ip_UserID);
        
        #=====REMOVE AFFECTED EVIDENCE==========================
		
		DELETE 	ce
		FROM 	CTS_DataCenter.CustEvidence AS ce
		WHERE	(	(ce.CTSCustID 	= ip_FromCTSCustID 	AND ce.FromCustID = vr_ToCTSCustID)
				OR 	(ce.CTSCustID	= vr_ToCTSCustID 	AND ce.FromCustID = ip_FromCTSCustID))
                AND ce.Level = 2;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(4,vr_SPName, CONCAT('Remove Affected Evidence: ip_FromCTSCustID_', ip_FromCTSCustID, ';ip_ToUserName_', ip_ToUserName,'(',vr_ToCTSCustID,')'), vr_CreatedDate, ip_UserID);        
            
		SET	vr_Error = 0;        
    END IF;
    
    SET op_Error = vr_Error;
    SET SESSION default_collation_for_utf8mb4 = utf8mb4_general_ci;
	
END$$

DELIMITER ;