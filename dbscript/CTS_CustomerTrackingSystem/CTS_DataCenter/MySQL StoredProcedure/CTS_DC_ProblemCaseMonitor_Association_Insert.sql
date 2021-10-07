/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ProblemCaseMonitor_Association_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemCaseMonitor_Association_Insert`(
		IN ip_ProblemCaseData 		JSON
    ,	IN ip_AssDeviceID 			BIGINT UNSIGNED
    ,	IN ip_AssIPID 				BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20211006@Aries.Nguyen
		Task:  Insert Problem Case data From Association[RedmineID: #162830]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20211006@Aries.Nguyen: Created [RedmineID: #162830]

		Param's Explanation (filtered by):

		Example: 
            - CALL CTS_DC_ProblemCaseMonitor_Association_Insert('[{"CustID":3}, {"CustID":4}]', 1,2);
	*/ 
	DECLARE	CONST_ProblemCase_SuspiciousAss	INT DEFAULT 4;
    
	INSERT IGNORE INTO CTS_DataCenter.ProblemCaseMonitor(CreatedDate, CustID, ProblemCaseID, CustSubID, InsertTime)
    SELECT   CURRENT_DATE() AS CreatedDate
		,	tmp.CustID
		, 	CONST_ProblemCase_SuspiciousAss
        ,	0
        ,	CURRENT_DATE() AS CreatedDate
	 FROM JSON_TABLE(ip_ProblemCaseData,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustID"
		 )) AS 	tmp
	 WHERE NOT EXISTS(SELECT 1 FROM CTS_DataCenter.ProblemCaseMonitor AS pcm 
			WHERE  pcm.CustID = tmp.CustID AND  pcm.ProblemCaseID = CONST_ProblemCase_SuspiciousAss);
	
    UPDATE CTS_DataCenter.SystemParameter AS sys
    SET sys.ParameterValue = ip_AssIPID
    WHERE sys.ParameterID = 21;  
    
    UPDATE CTS_DataCenter.SystemParameter AS sys
    SET sys.ParameterValue = ip_AssDeviceID
    WHERE sys.ParameterID = 22;  

END$$
DELIMITER ;