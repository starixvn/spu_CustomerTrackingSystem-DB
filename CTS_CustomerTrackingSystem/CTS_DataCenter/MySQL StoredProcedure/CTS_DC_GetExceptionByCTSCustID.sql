DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetExceptionByCTSCustID$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetExceptionByCTSCustID(IN ip_CTSCustID BIGINT)
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Get Exception by CTSCustID
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
	*/
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustException;
    CREATE TEMPORARY TABLE Temp_CustException
    (
		ExceptionCTSCustID 	BIGINT
        , ExceptionDate		DATETIME
        , Comment			VARCHAR(200)
        , CreatedBy			INT
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
                , us.UserName AS CreatedBy
    FROM		Temp_CustException AS ce_temp
    INNER JOIN	CTS_DataCenter.CTSCustomer AS ct
				ON ce_temp.ExceptionCTSCustID = ct.CTSCustID
	INNER JOIN	CTS_Admin.CTSUser AS us
				ON ce_temp.CreatedBy = us.UserID;    
		
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;