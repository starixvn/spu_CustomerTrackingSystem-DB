/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_Get`(
		IN ip_MatchID 			BIGINT UNSIGNED    
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_LiveIndicator		BOOLEAN     
    ,	IN ip_Reason			INT  
    ,	IN ip_ScoreList			VARCHAR(500)     
    ,	IN ip_GroupIDList		VARCHAR(2000)
    
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
			-	20211213@Casey.Huynh: Enhance MM, Return more data 'Verified Trans List', Remove input Parameter ip_EventDate [Redmine ID: 165606]
            -	20220110@Casey.Huynh: Enhance MM, BetID, Reason [Redmine ID: 166986]
            -	20221027@Casey.Huynh: Update Verify By Reason and Betteam [RedmineID: 179439]
            - 	20221122@Casey.Huynh: Update TotalScore to ScoreDiff [Redmine ID: #179499]
             -	20230109@Casey.Huynh: UpdateSoreDiff [Redmine ID: #182637]
            
		Param's Explanation (filtered by):
		
		Example:
			CALL CTS_DC_MatchMonitor_Details_Get(48995415,1,0,1,0,3,'1,2,3');

	*/   
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Score;
    CREATE TEMPORARY TABLE Temp_Score(
		ScoreDiff 	INT
	);
    /*
    DROP TEMPORARY TABLE IF EXISTS Temp_ReasonGroup;
    CREATE TEMPORARY TABLE Temp_ReasonGroup(
			GroupID BIGINT UNSIGNED
	);
    */       
	#======Score not include in Rule of (baseketball)
	IF ip_ScoreList IS NULL THEN 
		SET ip_ScoreList = '0';
    END IF;
    
    #============================================
	SET @sql = CONCAT("INSERT INTO Temp_Score (ScoreDiff) VALUES ('", REPLACE(ip_ScoreList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    /*
    SET @sql = CONCAT("INSERT INTO Temp_ReasonGroup (GroupID) VALUES ('", REPLACE(ip_GroupIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    */
	SELECT 	d.ListCustID
		,	d.ListTransID
		,	d.GroupID
		,	d.Reason
		,	d.ScoreDiff
	FROM   CTS_DataCenter.MatchMonitorDetails AS d
		INNER JOIN Temp_Score AS s ON s.ScoreDiff = d.ScoreDiff
	#	INNER JOIN Temp_ReasonGroup AS r ON r.GroupID = d.GroupID
	WHERE 	d.BettypeID = ip_BettypeID
		AND d.BetID = ip_BetID
		AND d.MatchID = ip_MatchID
		AND d.LiveIndicator = ip_LiveIndicator
		AND d.Reason = ip_Reason;
	
	SELECT	js.TransID
			, mdv.VerifiedDate
            , (SELECT UserName FROM CTS_Admin.CTSUser WHERE UserID = VerifiedBy) AS VerifiedBy
	FROM CTS_DataCenter.MatchMonitorDetailsVerifiedTrans AS mdv
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mdv.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	WHERE  	mdv.MatchID = ip_MatchID
		AND mdv.LiveIndicator = ip_LiveIndicator
        AND	mdv.BettypeID = ip_BettypeID
        AND	mdv.BetID = ip_BetID
        AND ((mdv.Reason = ip_Reason) OR mdv.Reason IS NULL);
        
END$$
DELIMITER ;
