/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS CTS_DC_MatchMonitor_Rule_CStest;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE CTS_DC_MatchMonitor_Rule_CStest(
	IN ip_TempGroupID INT
)
  SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(
			'[
				{"TransID":111928688806,"TransDate":"2021-05-17 07:48:52.527","MatchID":43606436,"LiveIndicator":1,"LiveHomeScore":1,"LiveAwayScore":0,"BettypeID":8,"CustID":38290463,"Stake":50}
			]');

		Example:
			
	*/
    DECLARE lv_CustList LONGTEXT;
    DECLARE lv_MaxGroupID INT;
	DECLARE lv_MinGroupID INT;
    DECLARE lv_AssGroupID INT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewGroup;
    CREATE TEMPORARY TABLE Temp_NewGroup(
			OriginGroupID 	INT
		,	AssGroupID 		INT
        ,	GroupID			INT
        ,	IsHedging		INT
	)ENGINE=MEMORY;        
        
	SELECT 	GROUP_CONCAT(CustID)
	INTO	lv_CustList
    FROM	CTS_DataCenter.MatchMonitorStaging
    WHERE	OriginGroupID = ip_TempGroupID;
    
    CALL CTS_DC_Association_GetGroup(lv_CustList);
    
    INSERT INTO Temp_NewGroup(OriginGroupID, AssGroupID, GroupID, IsHedging)
    SELECT	mms.OriginGroupID
			, tmpGp.GroupID AS AssGroupID
            , mms.GroupID
            , tmpGp.IsHedging
    FROM	CTS_DataCenter.MatchMonitorStaging AS mms
		INNER JOIN Temp_Group AS tmpGp ON mms.CustID =  tmpGp.CustID AND OriginGroupID = ip_TempGroupID 
	GROUP BY mms.OriginGroupID, tmpGp.GroupID , mms.GroupID, tmpGp.IsHedging
    HAVING	Sum(Stake)>=500;  
    
    UPDATE CTS_DataCenter.MatchMonitorStaging AS mms
		LEFT JOIN Temp_Group AS tmpGp ON mms.CustID = tmpGp.CustID 
	SET OriginGroupID = NULL
    WHERE OriginGroupID = ip_TempGroupID AND tmpGp.CustID IS NULL;
    
    SELECT AssGroupID 
    INTO lv_AssGroupID 
    FROM Temp_NewGroup WHERE AssGroupID > lv_AssGroupID ORDER BY AssGroupID LIMIT 1;   
	
    WHILE lv_AssGroupID IS NOT NULL
    DO
		SET @MaxGroup = NULL;
        
		UPDATE CTS_DataCenter.MatchMonitorStaging AS mms
			INNER JOIN Temp_Group AS tmpGp ON mms.CustID =  tmpGp.CustID
		SET 	GroupID = IFNULL(tmpGp.GroupID, @MaxGroup:= lv_MaxGroupID + 1)
		WHERE	OriginGroupID = ip_TempGroupID AND tmpGp.AssGroupID = lv_AssGroupID;
        
        SET lv_MaxGroupID = IFNULL(@MaxGroup,lv_MaxGroupID);
        /*****************/
        SELECT AssGroupID 
		INTO lv_AssGroupID 
		FROM Temp_NewGroup WHERE AssGroupID > lv_AssGroupID ORDER BY AssGroupID LIMIT 1;
    END WHILE;

	INSERT  INTO CTS_DataCenter.MatchMonitor(MatchID, BettypeID, EventDate, HomeID, AwayID,LeagueID,IsHedging)
    SELECT 	MatchID, BettypeID, EventDate, HomeID, AwayID, LeagueID, tmpNg.IsHedging
    FROM	CTS_DataCenter.MatchMonitorStaging AS mms
		INNER JOIN Temp_NewGroup AS tmpNg ON mms.OriginGroupID = tmpNg.OriginGroupID
	WHERE 	mms.OriginGroupID = ip_TempGroupID
    GROUP BY MatchID, BettypeID, EventDate, HomeID, AwayID, LeagueID, tmpNg.IsHedging;

    INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, BettypeID, EventDate, LiveIndicator, GroupID, TotalScore, LiveHomeScore
						, LiveAwayScore, IsHedging, ListCustID, ListTransID)
    SELECT	mms.MatchID
		,	mms.BettypeID
        ,	mms.EventDate
        ,	mms.LiveIndicator
        ,	mms.GroupID
        ,	mms.LiveHomeScore + mms.LiveAwayScore AS TotalScore
        ,	mms.LiveHomeScore
        ,	mms.LiveAwayScore
        ,	tmpNg.IsHedging
        ,	GROUP_CONCAT(DISTINCT mms.CustID) AS ListCustID
        ,	GROUP_CONCAT(DISTINCT mms.TransID) AS ListTransID
    FROM	CTS_DataCenter.MatchMonitorStaging AS mms
		INNER JOIN Temp_NewGroup AS tmpNg ON mms.OriginGroupID = tmpNg.OriginGroupID
	WHERE	mms.OriginGroupID = ip_TempGroupID
    GROUP BY mms.MatchID, mms.BettypeID, mms.EventDate, mms.LiveIndicator, mms.GroupID, mms.LiveHomeScore, mms.LiveAwayScore, tmpNg.IsHedging;
    
END$$
DELIMITER ;
