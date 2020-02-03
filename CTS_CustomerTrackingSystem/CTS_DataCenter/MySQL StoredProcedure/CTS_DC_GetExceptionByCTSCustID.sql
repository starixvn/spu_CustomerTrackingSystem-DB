DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetExceptionByCTSCustID$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetExceptionByCTSCustID(IN ip_CTSCustID BIGINT)
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Get Flag Info By CTSCustID
		DB:			CTS_DataCenter
		Original: Spec https://nexdev.net/projects/customer-tracking-system/wiki/CTS_-_General_Information_Panel
					IF account has 
		Revisions:
		Param's Explanation (filtered by):
	*/
    DECLARE		vrIsFlagged			TINYINT DEFAULT -1 ;  # 0: NOT Flag, 1: BlackFlaged, 2: Flagged; 
 
    CREATE TEMPORARY TABLE Temp_CustException
    (
		ExceptionCTSCustID 	BIGINT
        , ExceptionDate		DATETIME
        , Comment			VARCHAR(200)
        , CreatedBy			BIGINT

    );
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
    INSERT INTO Temp_CustException(ExceptionCTSCustID, ExceptionDate, Comment, CreatedBy)
	SELECT 	(CASE WHEN ce.FromCTSCustID != ip_CTSCustID THEN ce.FromCTSCustID 
				ELSE ce.ToCTSCustID END) AS ExceptionCTSCustID
			, CreatedDate
            , Comment
            , Createdby
    FROM	CTS_DataCenter.CustException AS ce
    WHERE	ce.FromCTSCustID = ip_CTSCustID
			OR ce.ToCTSCustID = ip_CTSCustID;
    
    SELECT 		ce_temp.ExceptionCTSCustID
				, ct.Username	AS UserName
                , ct.UserName2	AS LoginID
				, ce_temp.ExceptionDate
                , ce_temp.Comment
                , ce_temp.CreatedBy
    FROM		Temp_CustException AS ce_temp
    INNER JOIN	CTS_DataCenter.CTSCustomer AS ct
				ON ce_temp.ExceptionCTSCustID = ct.CTSCustID;    
		
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;