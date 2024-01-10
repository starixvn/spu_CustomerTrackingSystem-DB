/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleLopsidedBetting_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleLopsidedBetting_Complete`(
		IN ip_LopsideBetInfo JSON
)
  SQL SECURITY INVOKER
	BEGIN
	/*
		Created:	20240105@Casey.Huynh
		Task :		Match Monitor Rule LopsidedBetting
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20240105@Casey.Huynh: Created [Redmine ID: #197706]
            
		Param's Explanation (filtered by):	

		Example:
			CALL CTS_DC_MatchMonitor_RuleLopsidedBetting_Complete(
                @ip_TransGroup:='[{"MatchID":1,"LeagueID":1,"SportType":1,"EventDate":"2024-01-05","HomeID":1,"AwayID":2,"Liveindicator":1,"BettypeID":1,"HDP1":0.25,"HDP2":0,"ListCustID":"1,2,3","ListTransID":"1,2,3"}
								, {"MatchID":1,"LeagueID":1,"SportType":1,"EventDate":"2024-01-05","HomeID":1,"AwayID":2,"Liveindicator":1,"BettypeID":1,"HDP1":0.05,"HDP2":0,"ListCustID":"1,2,3","ListTransID":"4,5,6"}
								, {"MatchID":1,"LeagueID":1,"SportType":1,"EventDate":"2024-01-05","HomeID":1,"AwayID":2,"Liveindicator":1,"BettypeID":1,"HDP1":0,"HDP2":0.25,"ListCustID":"1,2,3","ListTransID":"7,8,9"}]');
	
    */ 

    DECLARE	CONST_MMREASON	TINYINT DEFAULT 4;    
   
    #================================================================================  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LopsidedBetting;
    CREATE TEMPORARY TABLE Temp_LopsidedBetting
    (
			MatchID 		INT
		,	LeagueID		INT
        ,	SportType		INT
        ,	EventDate 		DATETIME
        ,	HomeID			INT
        ,	AwayID			INT
        ,	Liveindicator	BOOLEAN
        ,	BettypeID		INT
        ,	HDP				DECIMAL(8,4)
        ,	ListCustID		LONGTEXT
        ,	ListTransID		LONGTEXT
        
        ,	PRIMARY KEY PK_Temp_LopsidedBetting(MatchID,Liveindicator,BettypeID,HDP)
    );
    
    #===================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_LopsidedBettingGroup;
    CREATE TEMPORARY TABLE Temp_LopsidedBettingGroup
    (
			MatchID 		INT
        ,	Liveindicator	BOOLEAN
        ,	BettypeID		INT
		,	HDP				DECIMAL(8,4)
        ,	MaxGroup		INT
        
        ,	PRIMARY KEY PK_Temp_LopsidedBetting(MatchID,Liveindicator,BettypeID,HDP)
    );
    
    INSERT IGNORE INTO Temp_LopsidedBetting(MatchID,LeagueID,SportType,EventDate,HomeID,AwayID,Liveindicator,BettypeID,HDP,ListCustID,ListTransID)
	SELECT 	js.MatchID
		,	js.LeagueID
		,	js.SportType
        ,	js.EventDate
		,	js.HomeID
		,	js.AwayID
        ,	js.Liveindicator
		,	js.BettypeID
		,	js.HDP1-HDP2 AS HDP
		,	js.ListCustID
		,	js.ListTransID
	FROM JSON_TABLE(ip_LopsideBetInfo,
					 "$[*]" COLUMNS(
								MatchID 		INT PATH "$.MatchID" 
							,	LeagueID		INT PATH "$.LeagueID" 
							,	SportType		INT PATH "$.SportType" 
							,	EventDate 		DATETIME PATH "$.EventDate" 
							,	HomeID			INT PATH "$.HomeID" 
							,	AwayID			INT PATH "$.AwayID" 
							,	Liveindicator	BOOLEAN PATH "$.Liveindicator" 
							,	BettypeID		INT PATH "$.BettypeID" 
							,	HDP1			DECIMAL(8,4) PATH "$.HDP1" 
							,	HDP2			DECIMAL(8,4) PATH "$.HDP2" 
							,	ListCustID		LONGTEXT PATH "$.ListCustID" 
							,	ListTransID		LONGTEXT PATH "$.ListTransID" 
						)
				) AS js;   
    
    INSERT INTO MatchMonitorDetails(MatchID, Liveindicator, BettypeID, HDP, GroupID, Reason, ListCustID, ListTransID, EventDate, InsertTime)
    SELECT 	tmpLB.MatchID
		,	tmpLB.Liveindicator
		,	tmpLB.BettypeID
		,	tmpLB.HDP
		,	IFNULL(MAX(mmd.GroupID),0) + 1 AS MaxGroup
		,	CONST_MMREASON AS Reason
		,	MAX(tmpLB.ListCustID)
		,	MAX(tmpLB.ListTransID)
        ,	MAX(tmpLB.EventDate)
		,	CURRENT_TIMESTAMP(3) AS InsertTime
	FROM Temp_LopsidedBetting AS tmpLB
		LEFT JOIN MatchMonitorDetails AS mmd ON mmd.MatchID = tmpLB.MatchID AND mmd.Liveindicator = tmpLB.Liveindicator 
														AND mmd.BettypeID = tmpLB.BettypeID AND mmd.HDP = tmpLB.HDP
                                                        AND mmd.Reason = CONST_MMREASON
	GROUP BY tmpLB.MatchID
		,	tmpLB.Liveindicator
		,	tmpLB.BettypeID
		,	tmpLB.HDP;
    
	INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(MatchID,LeagueID,SportType,EventDate,HomeID,AwayID,Liveindicator,BettypeID,Reason, InsertTime, InsertDate)
	SELECT 	tmpLB.MatchID
		,	tmpLB.LeagueID
		,	tmpLB.SportType
        ,	tmpLB.EventDate
		,	tmpLB.HomeID
		,	tmpLB.AwayID
        ,	tmpLB.Liveindicator
		,	tmpLB.BettypeID
		,	CONST_MMREASON AS Reason 
        ,	CURRENT_TIMESTAMP(3) AS InsertTime
        ,	DATE(CURRENT_TIMESTAMP(3)) AS InsertTime
	FROM Temp_LopsidedBetting AS tmpLB;
    		
END$$
DELIMITER ;
