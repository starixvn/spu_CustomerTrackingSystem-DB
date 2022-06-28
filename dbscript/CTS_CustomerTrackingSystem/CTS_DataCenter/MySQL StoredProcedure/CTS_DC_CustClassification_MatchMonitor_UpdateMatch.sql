/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_MatchMonitor_UpdateMatch`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_MatchMonitor_UpdateMatch`(
	IN ip_MatchJson JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220627@Casey.Huynh	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20220627@Casey.Huynh [Redmine ID: #174218]: Created 
            
		Param's Explanation:
        
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_UpdateMatch('[{"MatchID":1,"EventStatus":"Completed"}, {"MatchID":2,"EventStatus":"running"}]');
	 */ 
	DROP TEMPORARY TABLE IF EXISTS Temp_CompletedMatch;
    CREATE TEMPORARY TABLE Temp_CompletedMatch(
			MatchID	INT PRIMARY KEY 
	);
     
	INSERT INTO Temp_CompletedMatch(MatchID) 
	SELECT 	tmpJs.MatchID
	FROM JSON_TABLE(ip_MatchJson,
		 "$[*]" COLUMNS(
				MatchID 			BIGINT UNSIGNED PATH "$.MatchID"
			,	EventStatus 		BIGINT UNSIGNED	PATH "$.EventStatus"
		 )) AS tmpJs
	 WHERE tmpJs.EventStatus = 'Completed' 
			AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.MatchMonitorStagingLive AS ms WHERE ms.MatchID = tmpJs.MatchID);
         
	UPDATE CTS_DataCenter.MatchMonitor AS mm
		INNER JOIN Temp_CompletedMatch AS tmpMi ON mm.MatchID = tmpMi
    SET mm.ClassifyStatus = 2;
	    
END$$
DELIMITER ;