/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Common_BettypeSetting_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Common_BettypeSetting_Get`(
		ip_FunctionID 				TINYINT
	,	ip_SportTypeIDList 			TEXT
	,	ip_BettypeIDList 			TEXT
	,	ip_IsFilterMMDetection 		BOOLEAN
	,	ip_IsShowDetailsX			BOOLEAN
    ,	ip_Status					TINYINT 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20231122@Casey.Huynh
		Task :		Get Bettype List
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20231122@Casey.Huynh: Created [Redmine ID: #196396]
            -	20240530@Casey.Huynh: Saba Group Betting [Redmine ID: #191972]
            
		Param's Explanation (filtered by):
        	ip_FunctionID: 1, 2
		,	ip_SportTypeIDList: NULL-Gett ALL Bettype, else '1,2,43..'
		,	ip_BettypeIDList: NULL: Gett ALL Bettype, else '1,3,7...'
		,	ip_IsFilterMMDetection: 1- Get DetectMonitor Bettype Only
		,	ip_IsShowDetailsX BOOLEAN   #Show filter basketball Quater 1, quater 2.. )
        
		Example:        
		Service MM Detection: CALL CTS_DC_Common_BettypeSetting_Get(@ip_FunctionID:=1,@ip_SportTypeIDList:=NULL,@ip_BettypeIDList:=NULL,@ip_IsFilterMMDetection:=1,@ip_IsShowDetailsX:=0,@ip_Status:=1); 
		Filter MM: CALL CTS_DC_Common_BettypeSetting_Get_UAT1(@ip_FunctionID:=1,@ip_SportTypeIDList:=NULL,@ip_BettypeIDList:=NULL,@ip_IsFilterMMDetection:=0,@ip_IsShowDetailsX:=1,@ip_Status:=1);
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_SportTypeID;
	CREATE TEMPORARY TABLE Temp_SportTypeID (
			SportTypeID	INT PRIMARY KEY
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_BettypeID;
	CREATE TEMPORARY TABLE Temp_BettypeID (
			BettypeID	INT PRIMARY KEY
	);
	
    IF ip_SportTypeIDList IS NOT NULL THEN
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SportTypeID(SportTypeID) VALUES ('", REPLACE(ip_SportTypeIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;    
	END IF;
    
    IF ip_BetTypeIDList IS NOT NULL THEN
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_BettypeID(BettypeID) VALUES ('", REPLACE(ip_BetTypeIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1; 
    END IF;
    
    IF ip_IsShowDetailsX = 1 THEN    
		SELECT  (CASE WHEN sbs.LeagueGroupID = 0 THEN NULL ELSE LeagueGroupID END) AS LeagueGroupID
			,	sbs.SportTypeID
			,	sbs.SportName
            ,	sbs.BetTypeID
            ,	(CASE WHEN js.NameDetailsX <> '' THEN REPLACE(sbs.BettypeNameDisplay,' X ', CONCAT(' ',js.NameDetailsX,' '))  
							ELSE sbs.BettypeNameDisplay END) AS BettypeNameDisplay
			,	sbs.BetChoiceType
            ,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceHome'),'"','') AS BetChoiceHome
            ,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceHomeDisplay'),'"','') AS BetChoiceHomeDisplay
			,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceAway'),'"','') AS BetChoiceAway
            ,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceAwayDisplay'),'"','') AS BetChoiceAwayDisplay
            ,	sbs.BetIDPattern
            ,	sbs.IsMMDetection
            ,	sbs.IsDefaultSelected
            ,	sbs.PriorityOrder
            ,	js.NameDetailsX
		FROM CTS_DataCenter.SportBettypeSetting AS sbs
			LEFT JOIN Temp_SportTypeID AS tmpSt ON tmpSt.SportTypeID = sbs.SportTypeID
			LEFT JOIN Temp_BettypeID AS tmpBt ON tmpBt.BettypeID = sbs.BettypeID
            , JSON_TABLE(CONCAT('["', REPLACE(IFNULL(BetTypeNameDetailsX,''), ',', '","'), '"]'),
						  '$[*]' COLUMNS (NameDetailsX VARCHAR(1) PATH '$')) js
		WHERE 	sbs.Status = ip_Status
			AND	sbs.FunctionID = ip_FunctionID
			AND ((ip_SportTypeIDList IS NOT NULL AND tmpSt.SportTypeID IS NOT NULL)
					OR ip_SportTypeIDList IS NULL)
			AND ((ip_BetTypeIDList IS NOT NULL AND tmpBt.BettypeID IS NOT NULL)
					OR ip_BetTypeIDList IS NULL)
			AND (sbs.IsMMDetection = ip_IsFilterMMDetection OR IFNULL(ip_IsFilterMMDetection,0) = 0)
		ORDER BY LeagueGroupID, sbs.PriorityOrder, js.NameDetailsX ; 
	ELSE		   
		SELECT  (CASE WHEN sbs.LeagueGroupID = 0 THEN NULL ELSE LeagueGroupID END) AS LeagueGroupID
			,	sbs.SportTypeID
			,	sbs.SportName
            ,	sbs.BetTypeID
            , 	sbs.BetTypeNameDisplay
            ,	sbs.BetChoiceType
            ,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceHome'),'"','') AS BetChoiceHome
            ,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceHomeDisplay'),'"','') AS BetChoiceHomeDisplay
			,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceAway'),'"','') AS BetChoiceAway
            ,	REPLACE(json_extract(BetChoicePattern, '$.BetChoiceAwayDisplay'),'"','') AS BetChoiceAwayDisplay
            ,	sbs.BetIDPattern
            ,	sbs.IsMMDetection
            ,	sbs.IsDefaultSelected
            ,	sbs.PriorityOrder
		FROM CTS_DataCenter.SportBettypeSetting AS sbs
			LEFT JOIN Temp_SportTypeID AS tmpSt ON tmpSt.SportTypeID = sbs.SportTypeID
			LEFT JOIN Temp_BettypeID AS tmpBt ON tmpBt.BettypeID = sbs.BettypeID
		WHERE 	sbs.Status = ip_Status
			AND	sbs.FunctionID = ip_FunctionID
			AND ((ip_SportTypeIDList IS NOT NULL AND tmpSt.SportTypeID IS NOT NULL)
					OR ip_SportTypeIDList IS NULL)
			AND ((ip_BetTypeIDList IS NOT NULL AND tmpBt.BettypeID IS NOT NULL)
					OR ip_BetTypeIDList IS NULL)
			AND (sbs.IsMMDetection = ip_IsFilterMMDetection OR IFNULL(ip_IsFilterMMDetection,0) = 0)
		ORDER BY LeagueGroupID, PriorityOrder; 
        
	END IF;
END$$
DELIMITER ;

