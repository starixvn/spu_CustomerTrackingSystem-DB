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
            - 20220210@Aries.Nguyen: Re-arrange customer category/class for good/bad robot [Redmine ID: #167726]
		Param's Explanation (filtered by):

		Example: 
            - CALL CTS_DataCenter.CTS_DC_ProblemCaseMonitor_Classification_Get(@op_ClassificationHistoryID);
	*/ 
	DECLARE	CONST_ProblemCase_Robot 		    INT DEFAULT 1;
    DECLARE	CONST_ProblemCase_BadRobot 		    INT DEFAULT 10;
    DECLARE	CONST_ProblemCase_GoodRobot 		INT DEFAULT 11;
	DECLARE	CONST_ProblemCase_ProPunter 	    INT DEFAULT 9;
    DECLARE	CONST_CategoryID_BadRobot 		    INT DEFAULT 163;
	DECLARE	CONST_CategoryID_GoodRobot 	        INT DEFAULT 164;
    
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
        ,	CASE WHEN cat.CategoryID = CONST_CategoryID_BadRobot THEN CONST_ProblemCase_BadRobot
                 WHEN cat.CategoryID = CONST_CategoryID_GoodRobot THEN CONST_ProblemCase_GoodRobot
                 WHEN cat.CategoryGroup IN (59,61) THEN CONST_ProblemCase_Robot
				 WHEN cat.CategoryGroup IN (204) THEN CONST_ProblemCase_ProPunter END AS ProblemCaseID
    FROM CTS_DataCenter.CTSCustomerClassification_History AS his
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON his.CategoryID = cat.CategoryID AND cat.CategoryGroup IN (59, 61, 204)
    WHERE his.ID BETWEEN lv_LastHistoryID  AND lv_NextHistoryID
		AND	his.IsDataChanged = 1;  
	
    SET op_ClassificationHistoryID = lv_NextHistoryID + 1;
END$$
DELIMITER ;