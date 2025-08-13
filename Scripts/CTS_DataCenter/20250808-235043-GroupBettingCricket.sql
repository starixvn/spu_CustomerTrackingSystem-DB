/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250808@Logan.Nguyen
Task:	 	Match Monitor, GroupBettingCricket
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250808@Logan.Nguyen: Created [Redmine ID: #235043]
        - 20250807@Winfred.Pham: Created [Redmine ID: #235036 - 235035 - 235038]

Reviewer:
*/


/*******************************ALTER Table BettypeSetting*********************************/
USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.BettypeSetting 
MODIFY COLUMN BetTypeNameDetailsX VARCHAR(200);

/*******************************ALTER Table SportBettypeSetting*********************************/
USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.SportBettypeSetting 
MODIFY COLUMN BetTypeNameDetailsX VARCHAR(200);

/*******************************INITIAL BettypeSetting*********************************/
USE CTS_DataCenter;

/* Initial Cricket BettypeSetting */
UPDATE BettypeSetting
SET BetTypeNameDisplay = REPLACE(BetTypeNameDisplay, ' X ', ' [X] ')
WHERE BetTypeNameDetailsX IS NOT NULL;

SELECT * FROM BettypeSetting;

INSERT INTO CTS_DataCenter.BettypeSetting (
    BetTypeID, BetteamOrder, BetteamName, BetChoiceType, BetTypeName, BetTypeNameDetailsX, 
    BetTypeNameDisplay, BetIDPattern, BetTeamDB, BetteamShortName, Status, BettypeOrder
)
VALUES
    /* Away Over [X] Runs (X = 1–50) */
    (@lv_BetTypeID := 9608, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Away Over X Runs',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @lv_BetTypeNameDisplay := 'Away Over [X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20300'),
    (@lv_BetTypeID := 9608, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Away Over X Runs',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @lv_BetTypeNameDisplay := 'Away Over [X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20300'),

    /* Home Over [X] Runs (X = 1–50) */
    (@lv_BetTypeID := 9607, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Home Over X Runs',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @lv_BetTypeNameDisplay := 'Home Over [X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20100'),
    (@lv_BetTypeID := 9607, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Home Over X Runs',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @lv_BetTypeNameDisplay := 'Home Over [X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20100'),

    /* Away Group 1-[X] Runs (X = 5,6,10,12,15,20,25,30,35,40,45) */
    (@lv_BetTypeID := 9411, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Away Group 1-X Runs',
        @lv_BetTypeNameDetailsX := '5,6,10,12,15,20,25,30,35,40,45',
        @lv_BetTypeNameDisplay := 'Away Group 1-[X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20540'),
    (@lv_BetTypeID := 9411, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Away Group 1-X Runs',
        @lv_BetTypeNameDetailsX := '5,6,10,12,15,20,25,30,35,40,45',
        @lv_BetTypeNameDisplay := 'Away Group 1-[X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20540'),

    /* Home Group 1-[X] Runs (X = 5,6,10,12,15,20,25,30,35,40,45) */
    (@lv_BetTypeID := 9410, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Home Group 1-X Runs',
        @lv_BetTypeNameDetailsX := '5,6,10,12,15,20,25,30,35,40,45',
        @lv_BetTypeNameDisplay := 'Home Group 1-[X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20500'),
    (@lv_BetTypeID := 9410, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Home Group 1-X Runs',
        @lv_BetTypeNameDetailsX := '5,6,10,12,15,20,25,30,35,40,45',
        @lv_BetTypeNameDisplay := 'Home Group 1-[X] Runs', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20500'),

    /* Away Fall of Wicket [X] (X = 1–10) */
    (@lv_BetTypeID := 9429, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Away Fall of Wicket X',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10',
        @lv_BetTypeNameDisplay := 'Away Fall of Wicket [X]', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20640'),
    (@lv_BetTypeID := 9429, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Away Fall of Wicket X',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10',
        @lv_BetTypeNameDisplay := 'Away Fall of Wicket [X]', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20640'),

    /* Home Fall of Wicket [X] (X = 1–10) */
    (@lv_BetTypeID := 9428, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Home Fall of Wicket X',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10',
        @lv_BetTypeNameDisplay := 'Home Fall of Wicket [X]', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20600'),
    (@lv_BetTypeID := 9428, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Home Fall of Wicket X',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5,6,7,8,9,10',
        @lv_BetTypeNameDisplay := 'Home Fall of Wicket [X]', @lv_BetIDPattern := '80XX', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20600');

SELECT * FROM BettypeSetting WHERE BettypeID IN (9608,9607,9411,9410,9429,9428);


/*******************************INITIAL SportBettypeSetting*********************************/        
 USE CTS_DataCenter;
 
UPDATE SportBettypeSetting AS sbs
	INNER JOIN BettypeSetting AS bs ON bs.BettypeID = sbs.BettypeID
SET sbs.BetTypeNameDisplay = bs.BetTypeNameDisplay;

INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID, LeagueGroupID, SportTypeID, BetTypeID, SportName, BetTypeName, BetTypeNameDetailsX, BettypeNameDisplay,
 BetChoicePattern, BetChoiceType, BetIDPattern, IsMMDetection, IsMMParlayDetection, MMReason, IsDefaultSelected, Status, SportOrder)
VALUES
    -- Away Over [X] Runs (9608)
    (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=50, @BetTypeID:=9608, @SportName:='Cricket', @BetTypeName:='Away Over X Runs',
     @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
     @BettypeNameDisplay:='Away Over [X] Runs',
     @BetChoicePattern:='{"BetChoiceOver": "o", "BetChoiceUnder": "u", "BetChoiceOverDisplay": "o", "BetChoiceUnderDisplay": "u"}',
     @BetChoiceType:=2, @BetIDPattern:='80XX', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300),

    -- Home Over [X] Runs (9607)
    (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=50, @BetTypeID:=9607, @SportName:='Cricket', @BetTypeName:='Home Over X Runs',
     @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
     @BettypeNameDisplay:='Home Over [X] Runs',
     @BetChoicePattern:='{"BetChoiceOver": "o", "BetChoiceUnder": "u", "BetChoiceOverDisplay": "o", "BetChoiceUnderDisplay": "u"}',
     @BetChoiceType:=2, @BetIDPattern:='80XX', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300),

    -- Away Group 1-[X] Runs (9411)
    (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=50, @BetTypeID:=9411, @SportName:='Cricket', @BetTypeName:='Away Group 1-X Runs',
     @BetTypeNameDetailsX:='5,6,10,12,15,20,25,30,35,40,45',
     @BettypeNameDisplay:='Away Group 1-[X] Runs',
     @BetChoicePattern:='{"BetChoiceOver": "o", "BetChoiceUnder": "u", "BetChoiceOverDisplay": "o", "BetChoiceUnderDisplay": "u"}',
     @BetChoiceType:=2, @BetIDPattern:='80XX', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300),

    -- Home Group 1-[X] Runs (9410)
    (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=50, @BetTypeID:=9410, @SportName:='Cricket', @BetTypeName:='Home Group 1-X Runs',
     @BetTypeNameDetailsX:='5,6,10,12,15,20,25,30,35,40,45',
     @BettypeNameDisplay:='Home Group 1-[X] Runs',
     @BetChoicePattern:='{"BetChoiceOver": "o", "BetChoiceUnder": "u", "BetChoiceOverDisplay": "o", "BetChoiceUnderDisplay": "u"}',
     @BetChoiceType:=2, @BetIDPattern:='80XX', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300),

    -- Away Fall of Wicket [X] (9429)
    (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=50, @BetTypeID:=9429, @SportName:='Cricket', @BetTypeName:='Away Fall of Wicket X',
     @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10',
     @BettypeNameDisplay:='Away Fall of Wicket [X]',
     @BetChoicePattern:='{"BetChoiceOver": "o", "BetChoiceUnder": "u", "BetChoiceOverDisplay": "o", "BetChoiceUnderDisplay": "u"}',
     @BetChoiceType:=2, @BetIDPattern:='80XX', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300),

    -- Home Fall of Wicket [X] (9428)
    (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=50, @BetTypeID:=9428, @SportName:='Cricket', @BetTypeName:='Home Fall of Wicket X',
     @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10',
     @BettypeNameDisplay:='Home Fall of Wicket [X]',
     @BetChoicePattern:='{"BetChoiceOver": "o", "BetChoiceUnder": "u", "BetChoiceOverDisplay": "o", "BetChoiceUnderDisplay": "u"}',
     @BetChoiceType:=2, @BetIDPattern:='80XX', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300);

SELECT * FROM SportBettypeSetting WHERE BettypeID IN (9608,9607,9411,9410,9429,9428);

#=====================================FOR DANGER MONITOR FEATURE==============================================
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
SELECT 2 AS FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName, NULL AS BetTypeNameDetailsX,REPLACE(BettypeNameDisplay,'[X]', 'X'),BetChoicePattern,BetChoiceType,BetIDPattern,0 as IsMMDetection, 0 as IsMMParlayDetection, MMReason, IsDefaultSelected,Status 
FROM SportBettypeSetting 
WHERE  1 = (CASE WHEN SportTypeID = 5 AND BetTypeID IN (153,154,155,156) THEN 1 
				WHEN SportTypeID = 9 AND BetTypeID IN (704,707,708) THEN 1 
				WHEN SportTypeID = 6 AND BetTypeID IN (219,220,704,705) THEN 1 
				ELSE 0 END )
AND FunctionID = 1;
;

SELECT *
FROM SportBettypeSetting 
WHERE  1 = (CASE WHEN SportTypeID = 5 AND BetTypeID IN (153,154,155,156) THEN 1 
				WHEN SportTypeID = 9 AND BetTypeID IN (704,707,708) THEN 1 
				WHEN SportTypeID = 6 AND BetTypeID IN (219,220,704,705) THEN 1 
				ELSE 0 END )
	AND FunctionID = 2;

/*******************************INITIAL MatchMonitorRuleSetting*********************************/      
USE CTS_DataCenter;

/* Initial Cricket MatchMonitorRuleSetting 
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting (
    RuleGroupID, RuleStatus, RuleGroupDesc, Reason, SportType, LeagueGroupID, LeagueType, ReasonName, SportName, TimeStep,
    TotalStake, CustStake, TotalTicket, HighStake, HighStakeTicketPercent, MinOdds, MaxOdds, OddsSpread, ModifiedDate, Comments
)
VALUES
    (@lv_RuleGroupID := 1, @lv_RuleStatus := 1, @lv_RuleGroupDesc := 'Group Betting Detect', @lv_Reason := 0, @lv_SportType := 50,
     @lv_LeagueGroupID := 0, @lv_LeagueType := 2, @lv_ReasonName := 'Group Betting', @lv_SportName := 'Cricket', @lv_TimeStep := 180,
     @lv_TotalStake := 300, @lv_CustStake := NULL, @lv_TotalTicket := NULL, @lv_HighStake := NULL, @lv_HighStakeTicketPercent := NULL,
     @lv_MinOdds := NULL, @lv_MaxOdds := NULL, @lv_OddsSpread := NULL, @lv_ModifiedDate := NOW(), @lv_Comments := 'Time Step In Seconds')
;
*/ 


/* Check data

SELECT *
FROM CTS_DataCenter.SportBettypeSetting
WHERE FunctionID = 1  AND SportTypeID IN (50) AND LeagueGroupID = 0;

SELECT *
FROM CTS_DataCenter.SportBettypeSetting
WHERE FunctionID = 1  AND SportTypeID IN (50) AND LeagueGroupID = 0;

SELECT * FROM CTS_DataCenter.BettypeSetting  WHERE BettypeID IN (9608,9607,9411,9410,9429,9428) ;

SELECT * FROM CTS_DataCenter.MatchMonitorRuleSetting WHERE SportType = 50;
*/







