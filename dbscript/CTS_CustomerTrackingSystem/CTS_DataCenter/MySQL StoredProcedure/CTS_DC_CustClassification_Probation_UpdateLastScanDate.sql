/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_UpdateLastScanDate`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_UpdateLastScanDate`(IN ip_CustSport json)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Update Last Scanned for probation customer if it run completely
		DB:			CTS_DataCenter
        
		Original:
		Revisions:
			- [20201116@Irena.Vo][145028]: Add column LastScannedDate & Enhance logic
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET SQL_SAFE_UPDATES = 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport 
    (	  
		  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED        
        , INDEX				IX_Temp_CustSport_CTSCustID(CustID, SportGroupID)    
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID) 
	SELECT 		DISTINCT temp.CustID, temp.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) AS temp;
    
    UPDATE 		CTS_DataCenter.ProbationAccountMonitor AS pro
    INNER JOIN 	Temp_CustSport AS temp ON pro.CustID = temp.CustID AND pro.SportGroupID = temp.SportGroupID
    SET			pro.LastScannedDate = CURRENT_DATE();
    
    SET SQL_SAFE_UPDATES = 1;
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;     
END$$

DELIMITER ;

