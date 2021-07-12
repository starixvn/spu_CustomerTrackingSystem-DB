/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule`(
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
    DECLARE lv_CustList VARCHAR(8000);
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
    DECLARE lv_DetailsListTrans TEXT;
    DECLARE lv_NewNoOfHedging INT;
    DECLARE lv_CurrentNoOfHedging INT;
    DECLARE lv_MaxOldGroupID INT;
    DECLARE lv_DetailsGroupIDPre INT;
    
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
		,	ListCustID		VARCHAR(8000)
        ,	ListTransID		TEXT
        ,	IsHedging		INT
        ,	MinPreGroupID	INT
        ,	NoOfPreGroupID	INT
    );
    
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
    
    SELECT lv_CustList;
    CALL CTS_DC_Association_GetGroup(lv_CustList); /*Return CustAssociationGroup Into Temporary table "Temp_Group"*/
	
    INSERT INTO Temp_AssGroup(AssGroupID, ListCustID, ListTransID, IsHedging, MinPreGroupID, NoOfPreGroupID)
	SELECT	tmpGp.GroupID AS AssGroupID
		,	GROUP_CONCAT(DISTINCT mms.CustID) AS ListCustID
		,	GROUP_CONCAT(DISTINCT mms.TransID) AS ListTransID
		,	MAX(tmpGp.IsHedging) AS IsHedging
		,	MIN(mms.GroupID) AS MinPreGroupID
		,	COUNT(mms.GroupID) AS NoOfPreGroupID
	FROM	CTS_DataCenter.MatchMonitorStaging AS mms
		INNER JOIN Temp_Group AS tmpGp ON mms.CustID = tmpGp.CustID
	WHERE mms.OriginGroupID = ip_TempGroupID 
	GROUP BY tmpGp.GroupID
	HAVING SUM(Stake) >= 500 AND COUNT(DISTINCT mms.CustID) > 1;  
    
    /*****IF EXISTS ANY ASSOCIATION GROUP THEN CHECK GROUP BETTING ELSE END*****/
    IF EXISTS (SELECT 1 FROM Temp_AssGroup LIMIT 1)
    THEN         
               
        #====MatchMonitorDetaisl===============
        DROP TEMPORARY TABLE IF EXISTS Temp_OdlGroupID;
        CREATE TEMPORARY TABLE Temp_OdlGroupID(OldGroupID INT);
		
        INSERT INTO Temp_OdlGroupID(OldGroupID)
        SELECT DISTINCT GroupID 
        FROM CTS_DataCenter.MatchMonitorStaging AS mms 
        WHERE mms.MatchID = lv_MatchID AND  mms.LiveIndicator = lv_LiveIndicator AND mms.TotalScore = lv_TotalScore AND mms.BettypeID = lv_BettypeID
				AND mms.OriginGroupID = ip_TempGroupID AND GroupID IS NOT NULL;
              
		DELETE	mmd
        FROM	CTS_DataCenter.MatchMonitorDetails AS mmd
        INNER JOIN Temp_OdlGroupID AS tmp ON mmd.GroupID = tmp.OldGroupID 
        WHERE	mmd.MatchID = lv_MatchID AND  mmd.LiveIndicator = lv_LiveIndicator AND mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID;
        
        SET 	lv_MaxOldGroupID = 0;
        
        SELECT 	IFNULL(MAX(GroupID),0)
        INTO 	lv_MaxOldGroupID
        FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd
        WHERE	mmd.MatchID = lv_MatchID AND  mmd.LiveIndicator = lv_LiveIndicator AND mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID;
       
        SET @MaxGroupID = lv_MaxOldGroupID;
        
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, BettypeID, EventDate, LiveIndicator, GroupID
						, TotalScore, LiveHomeScore, LiveAwayScore, IsHedging, ListCustID, ListTransID)
		SELECT	lv_MatchID
			,	lv_BettypeID
			,	lv_EventDate
			,	lv_LiveIndicator
			,	@MaxGroupID := @MaxGroupID + 1
			,	lv_TotalScore
			,	lv_LiveHomeScore
			,	lv_LiveAwayScore
			,	tmpAg.IsHedging
			,	tmpAg.ListCustID
			,	tmpAg.ListTransID
		FROM	Temp_AssGroup AS tmpAg;
		#WHERE	tmpAg.AssGroupID = @AssGroupID;
        
        #====MatchMonitor===============
        SELECT COUNT(DISTINCT IsHedging) 
        INTO lv_NewNoOfHedging
        FROM CTS_DataCenter.MatchMonitorDetails AS mm 
		WHERE mm.MatchID = lv_MatchID AND mm.BettypeID = lv_BettypeID;
        
        SELECT COUNT(DISTINCT IsHedging) 
		INTO lv_CurrentNoOfHedging
		FROM CTS_DataCenter.MatchMonitor AS mm 
		WHERE mm.MatchID = lv_MatchID AND mm.BettypeID = lv_BettypeID;
        
        SET lv_NewNoOfHedging = IFNULL(lv_NewNoOfHedging,0);
        SET lv_CurrentNoOfHedging = IFNULL(lv_CurrentNoOfHedging,0);
        
        IF ( lv_NewNoOfHedging > lv_CurrentNoOfHedging ) THEN		
			INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(IsHedging, MatchID, BettypeID, EventDate, EventStatus, KickOffTime, HomeID, AwayID,LeagueID)
			SELECT 	DISTINCT tmpAg.IsHedging, lv_MatchID, lv_BettypeID, lv_EventDate, lv_EventStatus
					, lv_KickOffTime, lv_HomeID, lv_AwayID, lv_LeagueID
			FROM	Temp_AssGroup AS tmpAg;
		END IF;
        
        IF  ( lv_NewNoOfHedging = lv_CurrentNoOfHedging AND lv_NewNoOfHedging = 1) THEN
			UPDATE CTS_DataCenter.MatchMonitor AS mm
            SET mm.IsHedging = (SELECT MAX(IsHedging) FROM Temp_AssGroup)
            WHERE MatchID = lv_MatchID AND BettypeID = lv_BettypeID ;	
		END IF;       
        
        IF  ( lv_NewNoOfHedging < lv_CurrentNoOfHedging ) THEN
			DELETE mm
			FROM CTS_DataCenter.MatchMonitor AS mm
			 LEFT JOIN (SELECT COUNT(DISTINCT IsHedging) AS IsHedging FROM Temp_AssGroup) AS tmp ON tmp.IsHedging = mm.IsHedging
			WHERE 	mm.MatchID = lv_MatchID AND mm.BettypeID = lv_BettypeID
					AND tmp.IsHedging IS NULL;	
		END IF;   
   
		#====MatchMonitorStaging===============
        SELECT 	GroupID, ListTransID
		INTO 	lv_DetailsGroupID, lv_DetailsListTrans
		FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd 
		WHERE	mmd.MatchID = lv_MatchID AND mmd.LiveIndicator = lv_LiveIndicator 
			AND 	mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID AND mmd.GroupID > lv_MaxOldGroupID
		ORDER BY mmd.GroupID ASC
        LIMIT 1;

		WHILE lv_DetailsGroupID IS NOT NULL
        DO
			CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(lv_DetailsListTrans,',','BIGINT UNSIGNED');
            
            UPDATE CTS_DataCenter.MatchMonitorStaging mms
			INNER JOIN TempItemTable AS tmpIt ON mms.TransID = tmpIt.Item
            SET mms.GroupID = lv_DetailsGroupID;           
            
            SET lv_DetailsGroupIDPre = lv_DetailsGroupID;
            SET lv_DetailsGroupID = NULL;
            
            SELECT 	mmd.GroupID, mmd.ListTransID
			INTO 	lv_DetailsGroupID, lv_DetailsListTrans
			FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd 
			WHERE	mmd.MatchID = lv_MatchID AND mmd.LiveIndicator = lv_LiveIndicator 
					AND	mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID AND mmd.GroupID > lv_DetailsGroupIDPre
            ORDER BY mmd.GroupID ASC
			LIMIT 1;

        END WHILE;
	END IF; 
	
END$$
DELIMITER ;
