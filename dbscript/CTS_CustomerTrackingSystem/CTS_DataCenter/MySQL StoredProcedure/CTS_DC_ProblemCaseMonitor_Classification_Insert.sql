/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ProblemCaseMonitor_Classification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemCaseMonitor_Classification_Insert`(
		IN ip_ProblemCaseData 				JSON
    ,	IN ip_ClassificationHistoryID 		BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20211006@Aries.Nguyen
		Task:  Insert Problem Case data From Classification[RedmineID: #162830]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20211006@Aries.Nguyen: Created [RedmineID: #162830]

		Param's Explanation (filtered by):

		Example: 
            - CALL CTS_DC_ProblemCaseMonitor_Classification_Insert('[{"CustID":1, "ProblemCaseID":4}, {"CustID":3112, "ProblemCaseID":4}]', 2277382);
	*/ 
	INSERT IGNORE INTO CTS_DataCenter.ProblemCaseMonitor(CreatedDate, CustID,ProblemCaseID, CustSubID, InsertTime)
    SELECT  CURRENT_DATE() AS CreatedDate
		,	tmp.CustID
		, 	tmp.ProblemCaseID
        ,	0
        ,	CURRENT_TIME()	
	 FROM JSON_TABLE(ip_ProblemCaseData,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustID"
			, 	ProblemCaseID			SMALLINT 			PATH "$.ProblemCaseID"
		 )) AS 	tmp
	 WHERE NOT EXISTS(SELECT 1 FROM CTS_DataCenter.ProblemCaseMonitor AS pcm 
			WHERE tmp.CustID = pcm.CustID AND tmp.ProblemCaseID = pcm.ProblemCaseID);
	
    UPDATE CTS_DataCenter.SystemParameter AS sys
    SET sys.ParameterValue = ip_ClassificationHistoryID
    WHERE sys.ParameterID = 23;

END$$
DELIMITER ;