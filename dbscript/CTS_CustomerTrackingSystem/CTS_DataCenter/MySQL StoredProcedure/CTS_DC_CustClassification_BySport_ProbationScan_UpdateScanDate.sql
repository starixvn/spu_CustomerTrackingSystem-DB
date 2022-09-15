/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_BySport_ProbationScan_UpdateScanDate`;

DELIMITER $$
CREATE PROCEDURE `CTS_DC_CustClassification_BySport_ProbationScan_UpdateScanDate`(
        IN ip_CustSport JSON
)
    SQL SECURITY INVOKER 
BEGIN
	/*
		Created:	20220913@Harvey.Nguyen
		Task:		Update Last Scanned for probation customer if it run completely (For by sport)
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220907@Harvey.Nguyen: Initial [RedmineID: #177434]
		Param's Explanation (filtered by):
            -ip_CustSport:    
	*/

    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport (	  
		    CustID				BIGINT UNSIGNED
		,	SportID				SMALLINT UNSIGNED
        ,	PRIMARY KEY (CustID, SportID)
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID) 
	SELECT DISTINCT temp.CustID, temp.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 		BIGINT UNSIGNED		PATH "$.CustID"
			, SportID 		SMALLINT UNSIGNED	PATH "$.SportID"
		 )) AS temp;
    
    UPDATE CTS_DataCenter.ProbationAccountMonitor_BySport AS pro
        INNER JOIN Temp_CustSport AS temp ON pro.CustID = temp.CustID AND pro.SportID = temp.SportID
    SET pro.LastScannedDate = CURRENT_DATE();
    
END$$
DELIMITER ;