/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS CTS_DC_MatchMonitor_Rule;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE CTS_DC_MatchMonitor_Rule(
	IN ip_TempGroupID INT
)
  SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		CALL  CTS_DC_MatchMonitor_Rule(ip_TempGroupID);

		Example:
			
	*/
    DECLARE lv_CustList LONGTEXT;
    DECLARE lv_MaxGroupID	INT DEFAULT 0;
	DECLARE lv_MinGroupID	INT DEFAULT 0;
    DECLARE lv_AssGroupID	INT DEFAULT 0;
    DECLARE	lv_MatchID		BIGINT UNSIGNED;
    DECLARE	lv_BettypeID		INT;
    DECLARE	lv_EventDate		DATE;
    DECLARE	lv_LiveIndicator	INT;
    DECLARE	lv_TotalScore 		INT;
    DECLARE	lv_LiveHomeScore	SMALLINT UNSIGNED;
    DECLARE	lv_LiveAwayScore	SMALLINT UNSIGNED;
    DECLARE	lv_EventStatus		VARCHAR(50);
    DECLARE	lv_HomeID	INT UNSIGNED;
    DECLARE	lv_AwayID	INT UNSIGNED;
    DECLARE	lv_LeagueID	INT UNSIGNED;
    DECLARE	lv_KickOffTime	DATETIME;
    DECLARE lv_DetailsGroupID INT;
    DECLARE lv_DetailsListTrans VARCHAR(2000);
    
	DECLARE lv_StarTime DATETIME(3);
    SET lv_StarTime=current_timestamp(3);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssTransGroup;
    CREATE TEMPORARY TABLE Temp_AssTransGroup(
			MatchID			BIGINT UNSIGNED
		,   BettypeID		INT UNSIGNED
        ,	EventDate		DATE       
        ,   LiveIndicator	BIT
        ,	GroupID			INT
        ,	TotalScore		INT
        
        ,	PreGroupID		INT
        ,	NewGroupID		INT
		,	AssGroupID 		INT
        ,	IsHedging		INT
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssGroup;
    CREATE TEMPORARY TABLE Temp_AssGroup(
			AssGroupID		INT
		,	ListCustID		VARCHAR(2000)
        ,	ListTransID		VARCHAR(2000)
        ,	IsHedging		INT
        ,	MinPreGroupID	INT
        ,	NoOfPreGroupID	INT
    );
    /*
	DROP TEMPORARY TABLE IF EXISTS Temp_PreGroup;
    CREATE TEMPORARY TABLE Temp_PreGroup(
			AssGroupID	INT	
		,	PreGroupID	INT
	);
    */
   
	INSERT INTO  MatchMonitoringTrace(SPName, Value01, StartTime)
	VALUE ('CTS_DC_MatchMonitor_Rule', ip_TempGroupID, lv_StarTime);
   
	SELECT 	MatchID, LiveIndicator, TotalScore, BettypeID, EventDate, LiveHomeScore, LiveAwayScore
			, EventStatus, HomeID, AwayID, KickOffTime, LeagueID, KickOffTime
    INTO 	lv_MatchID, lv_LiveIndicator, lv_TotalScore, lv_BettypeID, lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore
			, lv_EventStatus, lv_HomeID, lv_AwayID, lv_KickOffTime, lv_LeagueID, lv_KickOffTime
    FROM  	CTS_DataCenter.MatchMonitorStaging
    WHERE	OriginGroupID = ip_TempGroupID 
    LIMIT 	1;
    
    /********GET CUST ASSOCIATION GROUP********/    
	SELECT 	GROUP_CONCAT(CustID)
	INTO	lv_CustList
    FROM	CTS_DataCenter.MatchMonitorStaging
    WHERE	OriginGroupID = ip_TempGroupID;    
    
    CALL CTS_DC_Association_GetGroup(lv_CustList); /*Return CustAssociationGroup Into Temporary table "Temp_Group"*/
   
    /*****IF EXISTS ANY ASSOCIATION GROUP THEN CHECK GROUP BETTING ELSE END*****/
    IF EXISTS (SELECT 1 FROM Temp_Group LIMIT 1)
    THEN

        INSERT INTO Temp_AssGroup(AssGroupID, ListCustID, ListTransID, IsHedging, MinPreGroupID, NoOfPreGroupID)
        SELECT	tmpGp.GroupID AS AssGroupID
			#,	CONCAT(',',GROUP_CONCAT(DISTINCT mms.CustID),',') AS ListCustID
			#,	CONCAT(',',GROUP_CONCAT(DISTINCT mms.TransID),',') AS ListTransID
            ,	GROUP_CONCAT(DISTINCT mms.CustID) AS ListCustID
            ,	GROUP_CONCAT(DISTINCT mms.TransID) AS ListTransID
			,	MAX(tmpGp.IsHedging) AS IsHedging
            ,	MIN(mms.GroupID) AS MinPreGroupID
            ,	COUNT(mms.GroupID) AS NoOfPreGroupID
		FROM	CTS_DataCenter.MatchMonitorStaging AS mms
			INNER JOIN Temp_Group AS tmpGp ON mms.CustID = tmpGp.CustID
		WHERE mms.OriginGroupID = ip_TempGroupID 
		GROUP BY tmpGp.GroupID
		HAVING SUM(Stake)>=500 AND COUNT(DISTINCT mms.CustID) > 1;           
        
        SET @NewNoOfHedging = (SELECT COUNT(DISTINCT IsHedging) FROM Temp_AssGroup);
        SET @CurrentNoOfHedging = IFNULL((SELECT COUNT(DISTINCT IsHedging) FROM CTS_DataCenter.MatchMonitor AS mm 
									WHERE mm.MatchID = lv_MatchID AND mm.BettypeID = lv_MatchID),0);
        
        IF ( @NewNoOfHedging > @CurrentNoOfHedging ) THEN			
			INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(IsHedging, MatchID, BettypeID, EventDate, EventStatus, KickOffTime, HomeID, AwayID,LeagueID)
			SELECT 	DISTINCT tmpAg.IsHedging, lv_MatchID, lv_BettypeID, lv_EventDate, lv_EventStatus
				, lv_KickOffTime, lv_HomeID, lv_AwayID, lv_LeagueID
			FROM	Temp_AssGroup AS tmpAg;    
		END IF;
        SET @MaxPreGroupID = 0;
      
        WHILE EXISTS (SELECT 1 FROM Temp_AssGroup LIMIT 1)
        DO
			SET @AssGroupID = 0;
			SET	@IsHedging = 0;
            SET @NoOfPreGroupID = 0;
    
            SELECT AssGroupID, IsHedging, NoOfPreGroupID INTO @AssGroupID, @IsHedging, @NoOfPreGroupID FROM Temp_AssGroup LIMIT 1;

            IF @NoOfPreGroupID = 0 THEN # Insert New Group To Details
				INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, BettypeID, EventDate, LiveIndicator, GroupID
						, TotalScore, LiveHomeScore, LiveAwayScore, IsHedging, ListCustID, ListTransID)
				SELECT	lv_MatchID
					,	lv_BettypeID
					,	lv_EventDate
					,	lv_LiveIndicator
					,	@MaxPreGroupID := @MaxPreGroupID + 1
					,	lv_TotalScore
					,	lv_LiveHomeScore
					,	lv_LiveAwayScore
					,	tmpAg.IsHedging
					,	tmpAg.ListCustID
					,	tmpAg.ListTransID
				FROM	Temp_AssGroup AS tmpAg
				WHERE	tmpAg.AssGroupID = @AssGroupID;
            ELSE # Update MinGroup and Remove the others GroupID  
			
				UPDATE  CTS_DataCenter.MatchMonitorDetails AS mmd
					INNER JOIN Temp_AssGroup AS tmpAg ON mmd.GroupID = tmpAg.MinPreGroupID AND tmpAg.AssGroupID = @AssGroupID 
								AND mmd.IsHedging = @IsHedging
				SET		mmd.ListCustID = tmpAg.ListCustID, mmd.ListTransID = tmpAg.ListTransID
				WHERE	mmd.MatchID = lv_MatchID AND mmd.LiveIndicator = lv_LiveIndicator AND mmd.TotalScore = lv_TotalScore 
						AND mmd.BettypeID = lv_BettypeID;
            END IF;
            #=================================================
            DELETE 	tmpAg
            FROM 	Temp_AssGroup AS tmpAg
            WHERE	tmpAg.AssGroupID = @AssGroupID;
        END WHILE;

		#======Update Last Group to Staging===========================================
        SELECT 	GroupID, ListTransID
		INTO 	lv_DetailsGroupID, lv_DetailsListTrans
		FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd 
		WHERE	mmd.MatchID = lv_MatchID AND mmd.LiveIndicator = lv_LiveIndicator 
			AND 	mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID AND mmd.GroupID > 0
		ORDER BY mmd.GroupID ASC
        LIMIT 1;
       
       
		WHILE lv_DetailsGroupID IS NOT NULL
        DO

			CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(lv_DetailsListTrans,',','BIGINT UNSIGNED');
                      
            UPDATE CTS_DataCenter.MatchMonitorStaging mms
			INNER JOIN TempItemTable AS tmpIt ON mms.TransID = tmpIt.Item
            SET mms.GroupID = lv_DetailsGroupID;           
            
            SET @DetailsGroupID = lv_DetailsGroupID;
            SET lv_DetailsGroupID = NULL;
            
            SELECT 	GroupID, mmd.ListTransID
			INTO 	lv_DetailsGroupID, lv_DetailsListTrans
			FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd 
			WHERE	mmd.MatchID = lv_MatchID AND mmd.LiveIndicator = lv_LiveIndicator 
					AND	mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID AND mmd.GroupID > @DetailsGroupID
            ORDER BY mmd.GroupID ASC
			LIMIT 1;

        END WHILE;

	END IF;
   
END$$
DELIMITER ;
