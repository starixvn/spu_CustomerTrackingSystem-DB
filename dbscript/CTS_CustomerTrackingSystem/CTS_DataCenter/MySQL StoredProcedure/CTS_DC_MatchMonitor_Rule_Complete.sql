/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule_Complete`(
		IN ip_LiveIndicator BOOLEAN
	, 	IN ip_MatchID		INT
    , 	IN ip_BettypeID		INT
    , 	IN ip_TotalScore	TINYINT
    , 	IN ip_TransGroup	JSON
)
  SQL SECURITY INVOKER
BEGIN
		/*Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
            -	20210719@Casey.Huynh: Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
            -	20210830@Casey.Huynh: Update Rule seperate Live and NonLive and move to Slave [Redmine ID: 159195]
		
		Param's Explanation (filtered by):
		CALLCTS_DC_MatchMonitor_Rule_Complete();

		Example:
			
	*/
 #   DECLARE	lv_Last3mMinTime 	DATETIME(3);
 #   DECLARE	lv_Last3mMaxTime 			DATETIME(3);  
#	DECLARE	lv_LastTransID 				BIGINT;   
    DECLARE lv_GroupID 					INT;
	DECLARE lv_IsHedging 				BOOLEAN;
    DECLARE lv_TransIDList 				LONGTEXT;
    DECLARE lv_CustIDList				LONGTEXT;
    DECLARE lv_OldGroupIDList			TEXT;
    DECLARE lv_NoOfOldGroupID			INT;
    DECLARE lv_EventDate 				DATE;
    DECLARE lv_LiveHomeScore			SMALLINT UNSIGNED;
    DECLARE lv_LiveAwayScore			SMALLINT UNSIGNED;
    DECLARE lv_MaxGroupID 				INT;
	DECLARE lv_MinGroupID 				INT;
    DECLARE lv_MatchHedging				BOOLEAN DEFAULT 0;
    DECLARE lv_MatchNotHedging 			BOOLEAN DEFAULT 0;
	DECLARE lv_MatchDetailsHedging		BOOLEAN DEFAULT 0;
    DECLARE lv_MatchDetailsNotHedging 	BOOLEAN DEFAULT 0;
    DECLARE	lv_KickOffTime 				DATETIME;
    DECLARE	lv_EventStatus 				VARCHAR(50);
    DECLARE lv_HomeID 					INT UNSIGNED;
    DECLARE lv_AwayID 					INT UNSIGNED;
    DECLARE lv_LeagueID					INT UNSIGNED;
    
/*    DROP TEMPORARY TABLE IF EXISTS Temp_Last3mTransGroup;
    CREATE TEMPORARY TABLE Temp_Last3mTransGroup
    (
			MatchID INT
        ,	TotalScore SMALLINT
        ,	BettypeID INT 
        ,   GroupID INT
        
        ,	PRIMARY KEY (MatchID,TotalScore,BettypeID,GroupID)
    );
    */
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
    CREATE TEMPORARY TABLE Temp_TransGroup
    (
			GroupID 		INT
        ,	IsHedging 		BOOLEAN
        ,	TransIDList 	LONGTEXT
        ,	CustIDList		LONGTEXT 
        ,	OldGroupIDList	TEXT 
        ,   NoOfOldGroupID	INT
        
        ,	PRIMARY KEY Temp_TransGroup(GroupID)
    );
    
    INSERT IGNORE INTO CTS_DataCenter.Temp_TransGroup(GroupID, IsHedging, TransIDList, CustIDList, OldGroupIDList, NoOfOldGroupID)
		SELECT  js.GroupID
			,	js.IsHedging
			,	js.TransIDList
			,	js.CustIDList
			,	js.OldGroupIDList
			,	js.NoOfOldGroupID
		FROM JSON_TABLE(ip_TransGroup,
						 "$[*]" COLUMNS(
									GroupID			INT PATH "$.GroupID" 
								,	IsHedging		BOOLEAN PATH "$.IsHedging" 
								,	TransIDList		LONGTEXT PATH "$.TransIDList"
								,	CustIDList		LONGTEXT PATH "$.CustIDList" 
								,	OldGroupIDList	TEXT PATH "$.OldGroupIDList" 
								,	NoOfOldGroupID	INT	PATH "$.NoOfOldGroupID" 
							)
					) AS js;  
    
   
    #======Update MatchMonitorDetails====================================
    SET lv_MaxGroupID = 0;
    
    SELECT MAX(GroupID)
    INTO lv_MaxGroupID
    FROM MatchMonitorDetails WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND TotalScore = ip_TotalScore;
    
    IF (ip_LiveIndicator = 1) THEN
		SELECT EventDate, LiveHomeScore, LiveAwayScore, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID
		FROM CTS_DataCenter.MatchMonitorStagingLive WHERE  MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND TotalScore = ip_TotalScore
		LIMIT 1;
	END IF;
    
     IF (ip_LiveIndicator = 0) THEN
		SELECT EventDate, LiveHomeScore, LiveAwayScore, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID
		FROM CTS_DataCenter.MatchMonitorStagingNonLive WHERE  MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND TotalScore = ip_TotalScore
		LIMIT 1;
	END IF;

	#SELECT lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID;

    lp: LOOP 
		SET lv_GroupID = 0;
        SELECT GroupID, IsHedging, TransIDList, CustIDList, OldGroupIDList, NoOfOldGroupID
        INTO lv_GroupID, lv_IsHedging, lv_TransIDList, lv_CustIDList, lv_OldGroupIDList, lv_NoOfOldGroupID
        FROM Temp_TransGroup
        ORDER BY GroupID LIMIT 1;

        IF lv_GroupID =0 
        THEN			
            LEAVE lp; 
        END IF;
        
        IF(lv_NoOfOldGroupID = 0) # INSERT NEW GROUP
        THEN
			SET lv_MaxGroupID = lv_MaxGroupID + 1;
            INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, LiveIndicator, TotalScore, BettypeID, EventDate, GroupID, LiveHomeScore, LiveAwayScore, ListCustID, ListTransID, IsHedging)
            VALUES(ip_MatchID, ip_LiveIndicator, ip_TotalScore, ip_BettypeID, lv_EventDate, lv_GroupID, lv_LiveHomeScore, lv_LiveAwayScore, lv_CustIDList, lv_TransIDList, lv_IsHedging);
        END IF; 
        
		IF (lv_NoOfOldGroupID = 1) THEN # UPDATE OLD GROUP			
			UPDATE CTS_DataCenter.MatchMonitorDetails
			SET GroupID = lv_GroupID, ListCustID = lv_CustIDList, ListTransID = lv_TransIDList, IsHedging = lv_IsHedging
			WHERE  LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND TotalScore = ip_TotalScore AND GroupID = lv_OldGroupIDList;
		END IF;
        
        IF (lv_NoOfOldGroupID > 1) THEN # MERGE GROUP
			CALL CTS_DC_Sys_SplitStringToTempItemTable(lv_OldGroupIDList,',','INT');
			SET lv_MinGroupID = (SELECT Item FROM TempItemTable ORDER BY Item LIMIT 1);
			
            DELETE mmd
            FROM CTS_DataCenter.MatchMonitorDetails AS mmd
				INNER JOIN TempItemTable AS tmpIt ON mmd.GroupID = tmpIt.Item
			WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.TotalScore = ip_TotalScore AND mmd.GroupID = lv_OldGroupIDList	AND mmd.GroupID <> lv_MinGroupID;
                    
			UPDATE CTS_DataCenter.MatchMonitorDetails
			SET GroupID = lv_GroupID, ListCustID = ip_CustIDList, ListTransID = lv_TransIDList, IsHedging = IsHedging
			WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND TotalScore = ip_TotalScore AND GroupID = lv_MinGroupID;
			
		END IF;
        
        DELETE tmptg
        FROM Temp_TransGroup AS tmptg WHERE GroupID = lv_GroupID;
        
        IF(ip_LiveIndicator = 1) THEN
			SET @sql = 	CONCAT("UPDATE CTS_DataCenter.MatchMonitorStagingLive
            SET GroupID = ",lv_GroupID,"
            WHERE TransID IN (",lv_TransIDList,")");
            /*
			UPDATE CTS_DataCenter.MatchMonitorStagingLive
            SET GroupID = lv_GroupID
            WHERE TransID IN (lv_TransIDList);*/
		ELSE
			SET @sql = 	CONCAT("UPDATE CTS_DataCenter.MatchMonitorStagingNonLive
            SET GroupID = ",lv_GroupID,"
            WHERE TransID IN (",lv_TransIDList,")");
        END IF;
      
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;  
    END LOOP;
    
    #======Update MatchMonitor===========================================
    SELECT 1
    INTO lv_MatchHedging
    FROM CTS_DataCenter.MatchMonitor 
    WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID  AND IsHedging = 1 
    LIMIT 1;
    
    SELECT 1
    INTO lv_MatchNotHedging
    FROM CTS_DataCenter.MatchMonitor 
    WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND IsHedging = 0  LIMIT 1;
    
	SELECT 1
    INTO lv_MatchDetailsHedging
    FROM CTS_DataCenter.MatchMonitorDetails 
    WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID AND IsHedging = 1  LIMIT 1;
    
    SELECT 1
    INTO lv_MatchDetailsNotHedging
    FROM CTS_DataCenter.MatchMonitorDetails 
    WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID  AND IsHedging = 0  LIMIT 1;
	
    IF(lv_MatchHedging +  lv_MatchNotHedging < lv_MatchDetailsHedging + lv_MatchDetailsNotHedging) THEN
		IF(lv_MatchHedging = 0 AND lv_MatchDetailsHedging = 1) THEN
			
			INSERT INTO CTS_DataCenter.MatchMonitor(MatchID,BettypeID, LiveIndicator, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, IsHedging)
			VALUES(ip_MatchID, ip_BettypeID, ip_LiveIndicator, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, 1);
		END IF;
        
        IF(lv_MatchNotHedging = 0 AND lv_MatchDetailsNotHedging = 1) THEN
			
			INSERT INTO CTS_DataCenter.MatchMonitor(MatchID,BettypeID, LiveIndicator, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, IsHedging)
			VALUES(ip_MatchID, ip_BettypeID, ip_LiveIndicator, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, 0);
		END IF;        
    END IF;
    
    IF(lv_MatchHedging +  lv_MatchNotHedging = lv_MatchDetailsHedging + lv_MatchDetailsNotHedging AND lv_MatchDetailsHedging + lv_MatchDetailsNotHedging = 1) THEN
		IF(lv_MatchHedging = 0 AND lv_MatchDetailsHedging = 1) THEN
			
			UPDATE CTS_DataCenter.MatchMonitor
            SET IsHedging = 1
            WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID;
		END IF;
        
        IF(lv_MatchHedging = 1 AND lv_MatchDetailsHedging = 0) THEN
			
			UPDATE CTS_DataCenter.MatchMonitor
            SET IsHedging = 0
            WHERE LiveIndicator = ip_LiveIndicator AND MatchID = ip_MatchID AND BettypeID = ip_BettypeID;
		END IF;       
    END IF;
    

   
END$$
DELIMITER ;
