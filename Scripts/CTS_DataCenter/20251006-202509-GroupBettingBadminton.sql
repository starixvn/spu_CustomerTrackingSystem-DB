/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251006@Logan.Nguyen
Task:	 	Match Monitor, GroupBettingCricket
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20251006@Logan.Nguyen: Created [Redmine ID: #202509]

Reviewer:
*/


/*******************************INITIAL BettypeSetting*********************************/
USE CTS_DataCenter;

UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDisplay = 'Game [X] Winner' WHERE (BetTypeID = 707) AND (BetteamOrder = 1);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDisplay = 'Game [X] Winner' WHERE (BetTypeID = 707) AND (BetteamOrder = 2);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDisplay = 'Game [X] Points HDP' WHERE (BetTypeID = 708) AND (BetteamOrder = 1);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDisplay = 'Game [X] Points HDP' WHERE (BetTypeID = 708) AND (BetteamOrder = 2);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDetailsX = '1,2,3,4,5' WHERE (BetTypeID = 707) AND (BetteamOrder = 1);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDetailsX = '1,2,3,4,5' WHERE (BetTypeID = 707) AND (BetteamOrder = 2);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDetailsX = '1,2,3,4,5' WHERE (BetTypeID = 708) AND (BetteamOrder = 1);
UPDATE CTS_DataCenter.BettypeSetting SET BetTypeNameDetailsX = '1,2,3,4,5' WHERE (BetTypeID = 708) AND (BetteamOrder = 2);

INSERT INTO CTS_DataCenter.BettypeSetting (
    BetTypeID, BetteamOrder, BetteamName, BetChoiceType, BetTypeName, BetTypeNameDetailsX, 
    BetTypeNameDisplay, BetIDPattern, BetTeamDB, BetteamShortName, Status, BettypeOrder
)
VALUES

    /* Match Handicap - Match HDP */
        (@lv_BetTypeID := 701, @lv_BetteamOrder := 1, @lv_BetteamName := 'Home', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Match Handicap',
        @lv_BetTypeNameDetailsX := NULL,
        @lv_BetTypeNameDisplay := 'Match HDP', @lv_BetIDPattern := NULL, @lv_BetTeamDB := 'h', @lv_BetteamShortName := 'h', @lv_Status := 1, @lv_BettypeOrder := '20200')
    ,   (@lv_BetTypeID := 701, @lv_BetteamOrder := 2, @lv_BetteamName := 'Away', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Match Handicap',
        @lv_BetTypeNameDetailsX := NULL,
        @lv_BetTypeNameDisplay := 'Match HDP', @lv_BetIDPattern := NULL, @lv_BetTeamDB := 'a', @lv_BetteamShortName := 'a', @lv_Status := 1, @lv_BettypeOrder := '20200')

    /*  Game (X) Point Over/Under - Game (X) Point O/U */
    ,   (@lv_BetTypeID := 709, @lv_BetteamOrder := 1, @lv_BetteamName := 'Over', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Game X Point Over/Under',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5',
        @lv_BetTypeNameDisplay := 'Game [X] Point O/U', @lv_BetIDPattern := '80X', @lv_BetTeamDB := 'o', @lv_BetteamShortName := 'o', @lv_Status := 1, @lv_BettypeOrder := '20200')
    ,   (@lv_BetTypeID := 709, @lv_BetteamOrder := 2, @lv_BetteamName := 'Under', @lv_BetChoiceType := 2, @lv_BetTypeName := 'Game X Point Over/Under',
        @lv_BetTypeNameDetailsX := '1,2,3,4,5',
        @lv_BetTypeNameDisplay := 'Game [X] Point O/U', @lv_BetIDPattern := '80X', @lv_BetTeamDB := 'u', @lv_BetteamShortName := 'u', @lv_Status := 1, @lv_BettypeOrder := '20200')
;

SELECT * FROM BettypeSetting WHERE BettypeID IN (701,705,709,707,708);


/*******************************INITIAL SportBettypeSetting*********************************/        
USE CTS_DataCenter;

UPDATE CTS_DataCenter.SportBettypeSetting SET BetTypeNameDetailsX = '1,2,3,4,5' WHERE LeagueGroupID = 0 AND SportTypeID = 9 AND BetTypeID in (708,707); 
UPDATE CTS_DataCenter.SportBettypeSetting SET BettypeNameDisplay = 'Game [X] Points HDP' WHERE LeagueGroupID = 0 AND SportTypeID = 9 AND BetTypeID = 708;
UPDATE CTS_DataCenter.SportBettypeSetting SET BettypeNameDisplay = 'Game [X] Winner' WHERE LeagueGroupID = 0 AND SportTypeID = 9 AND BetTypeID = 707;

INSERT INTO CTS_DataCenter.SportBettypeSetting
    (FunctionID,SportTypeID,LeagueGroupID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status,SportOrder)
VALUES 
        /* Match Handicap - Match HDP */
        (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=9, @BetTypeID:=701, @SportName:='Badminton', @BetTypeName:='Match Handicap',
        @BetTypeNameDetailsX:=null,
        @BettypeNameDisplay:='Match HDP',
        @BetChoicePattern:='{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',
        @BetChoiceType:=2, @BetIDPattern:=null, @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300)

        /* Match Points Over/Under - Match Points O/U */
    ,   (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=9, @BetTypeID:=705, @SportName:='Badminton', @BetTypeName:='Match Points Over/Under',
        @BetTypeNameDetailsX:=null,
        @BettypeNameDisplay:='Match Points O/U',
        @BetChoicePattern:='{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',
        @BetChoiceType:=2, @BetIDPattern:=null, @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300)
        /*  Game (X) Point Over/Under - Game (X) Point O/U */
    ,   (@FunctionID:=1, @LeagueGroupID:=0, @SportTypeID:=9, @BetTypeID:=709, @SportName:='Badminton', @BetTypeName:='Game X Point Over/Under',
        @BetTypeNameDetailsX:='1,2,3,4,5',
        @BettypeNameDisplay:=' Game [X] Point O/U',
        @BetChoicePattern:='{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',
        @BetChoiceType:=2, @BetIDPattern:='80X', @IsMMDetection:=1, @IsMMParlayDetection:=0, @MMReason:=0, @IsDefaultSelected:=0, @Status:=1, @SportOrder:=300)
;

SELECT * FROM SportBettypeSetting WHERE BettypeID IN (701,705,709,707,708);







