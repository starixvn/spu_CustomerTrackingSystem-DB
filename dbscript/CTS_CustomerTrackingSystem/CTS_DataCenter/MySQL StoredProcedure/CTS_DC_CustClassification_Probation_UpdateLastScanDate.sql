DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_Probation_UpdateLastScanDate$$
CREATE DEFINER=ctsService@`%` PROCEDURE CTS_DataCenter.CTS_DC_CustClassification_Probation_UpdateLastScanDate(IN ip_CustSport JSON)
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Update Last Scanned for probation customer if it run completely
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport 
    (	  
		  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED        
        , PRIMARY KEY	PK_Temp_CustSport_CTSCustID(CustID, SportGroupID)    
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) as tmpTable;
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cl
    INNER JOIN 	Temp_CustSport AS tmpCs
				ON cl.CustID = tmpCs.CustID
				AND	cl.SportGroupID = tmpCs.SportGroupID
    SET			cl.LastScannedDate = GREATEST(vrScanDate, cl.LastScannedDate);
    
END$$
DELIMITER ;

