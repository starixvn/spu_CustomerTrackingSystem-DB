/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ProblemCaseMonitor_Classification_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemCaseMonitor_Classification_Get`(
		OUT op_ClassificationHistoryID 		BIGINT UNSIGNED 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20211006@Aries.Nguyen
		Task:  Get Problem Case data From Classification[RedmineID: #162830]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20211006@Aries.Nguyen: Created [RedmineID: #162830]

		Param's Explanation (filtered by):

		Example: 
            - CALL CTS_DataCenter.CTS_DC_ProblemCaseMonitor_Classification_Get(@op_ClassificationHistoryID);
	*/ 
	DECLARE	CONST_ProblemCase_Robot 		INT DEFAULT 1;
	DECLARE	CONST_ProblemCase_ProPunter 	INT DEFAULT 9;
    
    DECLARE lv_LastHistoryID				BIGINT UNSIGNED;
	DECLARE lv_NextHistoryID				BIGINT UNSIGNED;
    DECLARE lv_BatchSize					INT;
	
    SELECT ParameterValue 
    INTO lv_LastHistoryID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 23;
    
    SELECT ParameterValue 
    INTO lv_BatchSize
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 50;
	
    SELECT MAX(tbl.ID)
    INTO lv_NextHistoryID
    FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_History
		  WHERE ID > lv_LastHistoryID
		  ORDER BY ID ASC
		  LIMIT lv_BatchSize) AS tbl;
    
    IF lv_NextHistoryID IS NULL THEN
		SET lv_NextHistoryID = lv_LastHistoryID;
    END IF;
    
    SELECT 	CustID
        ,	CASE WHEN his.CategoryID IN (59,61,79,81,159,161,204,271,272,273,277,278) THEN CONST_ProblemCase_Robot
				 WHEN his.CategoryID IN (204,271,272,273,277,278) THEN CONST_ProblemCase_ProPunter END AS ProblemCaseID
    FROM CTS_DataCenter.CTSCustomerClassification_History AS his
    WHERE his.ID BETWEEN lv_LastHistoryID  AND lv_NextHistoryID
		AND	his.IsDataChanged = 1 
        AND his.CategoryID IN (59,61,79,81,159,161,204,271,272,273,277,278);  
	
    SET op_ClassificationHistoryID = lv_NextHistoryID;
END$$
DELIMITER ;