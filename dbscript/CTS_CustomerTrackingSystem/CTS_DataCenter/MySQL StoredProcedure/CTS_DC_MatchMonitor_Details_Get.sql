/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_Get`(
	IN ip_EventDate			DATE,
    IN ip_MatchID 			BIGINT UNSIGNED,
    IN ip_BettypeID			INT UNSIGNED,
    IN ip_LiveIndicator		BIT,
    IN ip_ListScore			VARCHAR(200),
    IN ip_ListReasonGroup	VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Get Match Monitor Details report
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		
		Example:
			-	CALL CTS_DC_MatchMonitor_Details_Get('2021-05-01',12345,1,1,'1,2,3','100001,100002,100003');
	*/
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Score;
    CREATE TEMPORARY TABLE Temp_Score(
		TotalScore 	SMALLINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ReasonGroup;
    CREATE TEMPORARY TABLE Temp_ReasonGroup(
		GroupID 	BIGINT UNSIGNED
	);
 
	SET @sql = CONCAT("INSERT INTO Temp_Score (TotalScore) VALUES ('", REPLACE(ip_ListScore, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SET @sql = CONCAT("INSERT INTO Temp_ReasonGroup (GroupID) VALUES ('", REPLACE(ip_ListReasonGroup, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SELECT 	d.ListCustID
		,	d.ListTransID
        ,	d.GroupID
        ,	d.IsHedging
        ,	d.TotalScore
	FROM   CTS_DataCenter.MatchMonitorDetails AS d
		INNER JOIN Temp_Score AS s ON s.TotalScore = d.TotalScore
        INNER JOIN Temp_ReasonGroup AS r ON r.GroupID = d.GroupID
	WHERE  d.EventDate = ip_EventDate
		AND d.BettypeID = ip_BettypeID
        AND d.MatchID = ip_MatchID
        AND	(ip_LiveIndicator IS NULL OR d.LiveIndicator = ip_LiveIndicator)
        ;
    
END$$
DELIMITER ;
