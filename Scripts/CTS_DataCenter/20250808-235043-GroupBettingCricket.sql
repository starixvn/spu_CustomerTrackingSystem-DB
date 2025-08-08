/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250808@Logan.Nguyen
Task:	 	Match Monitor, GroupBettingCricket
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250808@Logan.Nguyen: Created [Redmine ID: #235043]

Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID, BetteamOrder, BetteamName, BetChoiceType, BetTypeName, BetTypeNameDetailsX, BetTypeNameDisplay, BetIDPattern, BetTeamDB, BetteamShortName, Status, BettypeOrder)
VALUES
    -- Away Over X Runs (X = 1–50)
    (@BetTypeID:=9608, @BetteamOrder:=1, @BetteamName:='Over', @BetChoiceType:=2, @BetTypeName:='Away Over X Runs',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @BetTypeNameDisplay:='Away Over X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='o', @BetteamShortName:='o', @Status:=1, @BettypeOrder:='20300'),
    (@BetTypeID:=9608, @BetteamOrder:=2, @BetteamName:='Under', @BetChoiceType:=2, @BetTypeName:='Away Over X Runs',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @BetTypeNameDisplay:='Away Over X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='u', @BetteamShortName:='u', @Status:=1, @BettypeOrder:='20400'),    

    -- Home Over X Runs (X = 1–50)
    (@BetTypeID:=9607, @BetteamOrder:=1, @BetteamName:='Over', @BetChoiceType:=2, @BetTypeName:='Home Over X Runs',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @BetTypeNameDisplay:='Home Over X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='o', @BetteamShortName:='o', @Status:=1, @BettypeOrder:='20100'),
    (@BetTypeID:=9607, @BetteamOrder:=2, @BetteamName:='Under', @BetChoiceType:=2, @BetTypeName:='Home Over X Runs',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
        @BetTypeNameDisplay:='Home Over X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='u', @BetteamShortName:='u', @Status:=1, @BettypeOrder:='20200'),
        
    -- Away Group 1-X Runs (X = 5,6,10,12,15,20,25,30,35,40,45)
    (@BetTypeID:=9411, @BetteamOrder:=1, @BetteamName:='Over', @BetChoiceType:=2, @BetTypeName:='Away Group 1-X Runs',
        @BetTypeNameDetailsX:='5,6,10,12,15,20,25,30,35,40,45',
        @BetTypeNameDisplay:='Away Group 1-X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='o', @BetteamShortName:='o', @Status:=1, @BettypeOrder:='20540'),
    (@BetTypeID:=9411, @BetteamOrder:=2, @BetteamName:='Under', @BetChoiceType:=2, @BetTypeName:='Away Group 1-X Runs',
        @BetTypeNameDetailsX:='5,6,10,12,15,20,25,30,35,40,45',
        @BetTypeNameDisplay:='Away Group 1-X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='u', @BetteamShortName:='u', @Status:=1, @BettypeOrder:='20560'),
        
    -- Home Group 1-X Runs (X = 5,6,10,12,15,20,25,30,35,40,45)
    (@BetTypeID:=9410, @BetteamOrder:=1, @BetteamName:='Over', @BetChoiceType:=2, @BetTypeName:='Home Group 1-X Runs',
        @BetTypeNameDetailsX:='5,6,10,12,15,20,25,30,35,40,45',
        @BetTypeNameDisplay:='Home Group 1-X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='o', @BetteamShortName:='o', @Status:=1, @BettypeOrder:='20500'),
    (@BetTypeID:=9410, @BetteamOrder:=2, @BetteamName:='Under', @BetChoiceType:=2, @BetTypeName:='Home Group 1-X Runs',
        @BetTypeNameDetailsX:='5,6,10,12,15,20,25,30,35,40,45',
        @BetTypeNameDisplay:='Home Group 1-X Runs', @BetIDPattern:='8XXX', @BetTeamDB:='u', @BetteamShortName:='u', @Status:=1, @BettypeOrder:='20520'),
        
    -- Away Fall of Wicket X (X = 1–10)
    (@BetTypeID:=9429, @BetteamOrder:=1, @BetteamName:='Over', @BetChoiceType:=2, @BetTypeName:='Away Fall of Wicket X',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10',
        @BetTypeNameDisplay:='Away Fall of Wicket X', @BetIDPattern:='8XXX', @BetTeamDB:='o', @BetteamShortName:='o', @Status:=1, @BettypeOrder:='20640'),
    (@BetTypeID:=9429, @BetteamOrder:=2, @BetteamName:='Under', @BetChoiceType:=2, @BetTypeName:='Away Fall of Wicket X',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10',
        @BetTypeNameDisplay:='Away Fall of Wicket X', @BetIDPattern:='8XXX', @BetTeamDB:='u', @BetteamShortName:='u', @Status:=1, @BettypeOrder:='20680'),
        
    -- Home Fall of Wicket X (X = 1–10)
    (@BetTypeID:=9428, @BetteamOrder:=1, @BetteamName:='Over', @BetChoiceType:=2, @BetTypeName:='Home Fall of Wicket X',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10',
        @BetTypeNameDisplay:='Home Fall of Wicket X', @BetIDPattern:='8XXX', @BetTeamDB:='o', @BetteamShortName:='o', @Status:=1, @BettypeOrder:='20600'),
    (@BetTypeID:=9428, @BetteamOrder:=2, @BetteamName:='Under', @BetChoiceType:=2, @BetTypeName:='Home Fall of Wicket X',
        @BetTypeNameDetailsX:='1,2,3,4,5,6,7,8,9,10',
        @BetTypeNameDisplay:='Home Fall of Wicket X', @BetIDPattern:='8XXX', @BetTeamDB:='u', @BetteamShortName:='u', @Status:=1, @BettypeOrder:='20620');
        
