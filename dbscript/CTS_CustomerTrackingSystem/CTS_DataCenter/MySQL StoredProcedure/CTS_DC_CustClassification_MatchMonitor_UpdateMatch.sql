/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_MatchMonitor_UpdateMatch`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_MatchMonitor_UpdateMatch`(
	IN ip_MatchJs JSON
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
			- CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_UpdateMatch('[{"MatchID":1,"EventStatus":"Completed"}]');
	 */ 
     
    CREATE TEMPORARY TABLE Temp_MatchInfo(
			MatchID	INT PRIMARY KEY
        ,	ClassifyStatus TINYINT     
       );
     
	INSERT INTO Temp_Customer(MatchID, ClassifyStatus) 
	SELECT 	temp.MatchID
		,	(CASE WHEN EventStatus = 'Completed' THEN ClassifyStatus = 1 ELSE ClassifyStatus END) AS ClassifyStatus
	FROM JSON_TABLE(ip_CustJson,
		 "$[*]" COLUMNS(
				MatchID 			BIGINT UNSIGNED	PATH "$.MatchID"
			,	EventStatus 		BIGINT UNSIGNED	PATH "$.MatchID"
		 )) AS temp;
	    
END$$
DELIMITER ;