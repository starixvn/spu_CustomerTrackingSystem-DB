/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ProblemCaseMonitor_Rule`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemCaseMonitor_Rule`(
	ip_PackSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20210617@Casey.Huynh
		Task:  Generate Problem Case data [RedmineID: #156464]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20210612@Casey.Huynh: Created [RedmineID: #156464]
		Param's Explanation (filtered by):

		Example: ;
	*/ 
    
    DECLARE lv_sysLastAssByIP DATETIME;
    DECLARE lv_sysLastAssByDevice BIGINT UNSIGNED;
    DECLARE lv_sysLastClassification BIGINT UNSIGNED;
    
    
    
    
    #===========================================================
    SET lv_sysLastAssByIP = (SELECT MAX(ParameterValue) FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 21);
    SET lv_sysLastAssByDevice = (SELECT MAX(ParameterValue) FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 22);
    SET lv_sysLastClassification = (SELECT MAX(ParameterValue) FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 23);
        
    #====GET ROBOT CategoryID IN (204,====================================================
    SET @LastCustClassHisID = lv_sysLastClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
    CREATE TEMPORARY TABLE Temp_Category
    (
			CategoryID INT PRIMARY KEY
        ,	CategoryGroup INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustProlemCase;
    CREATE TEMPORARY TABLE Temp_CustProlemCase
    (		
			CustID			BIGINT UNSIGNED
		,	ProblemCaseID	SMALLINT
        ,	CreatedDate		DATETIME        
        ,	ID				BIGINT	
        
        ,	PRIMARY KEY Temp_CustProlemCase_CustID_ProblemCaseID(CustID,ProblemCaseID)
	);
    #======Scan CTSCustomerClassification_History FOR cat.CategoryGroup IN (59, 61, 204)
    INSERT IGNORE INTO Temp_CustProlemCase (ID, CreatedDate, CustID, ProblemCaseID)
    SELECT 	@LastCustClassHisID := his.ID
		,	DATE(his.LastModifiedDate) AS CreatedDate
		,	CustID
        ,	(CASE WHEN cat.CategoryGroup IN (59,61) THEN 1
				 WHEN cat.CategoryGroup IN (204) THEN 9	END) AS ProblemCaseID
    FROM CTS_DataCenter.CTSCustomerClassification_History AS his
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON his.CategoryID = cat.CategoryID
    WHERE his.ID > lv_sysLastClassification AND his.IsDataChanged = 1 AND cat.CategoryGroup IN (59, 61, 204)
    ORDER BY ID
    LIMIT ip_PackSize;   
    
    INSERT INTO CTS_DataCenter.ProblemCaseMonitor(CreatedDate, ProblemCaseID, CustID, CustSubID, InsertTime)
    SELECT tmpCpc.CreatedDate, tmpCpc.ProblemCaseID, tmpCpc.CustID, 0 , CURRENT_TIME()
    FROM Temp_CustProlemCase AS tmpCpc
		LEFT JOIN CTS_DataCenter.ProblemCaseMonitor AS pcm ON tmpCpc.CustID = pcm.CustID AND tmpCpc.ProblemCaseID = pcm.ProblemCaseID
    WHERE pcm.ProblemCaseID IS NULL;    
    
    #======Scan AssociaionByDevice=======================================

    
    
	#=====================================================================
    UPDATE CTS_DataCenter.SystemParameter AS sys
    SET sys.ParameterValue = @LastCustClassHisID
    WHERE sys.ParameterID = 23;    
    
END$$

DELIMITER ;

CALL CTS_DC_ProblemCaseMonitor_Rule(5000);
SELECT COUNT(1) FROM ProblemCaseMonitor; #165;