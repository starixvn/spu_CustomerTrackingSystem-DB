/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleArbitrage_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleArbitrage_Complete`(
		IN ip_LiveIndicator BOOLEAN
	,	IN ip_MaxSequenceID	BIGINT UNSIGNED
	, 	IN ip_MatchID		INT
    , 	IN ip_ScoreDiff		INT 
    , 	IN ip_BettypeID		INT
    ,	IN ip_BetID			BIGINT
    ,	IN ip_HDP			DECIMAL(8,4)
    , 	IN ip_TransGroup	JSON
    
)


  SQL SECURITY INVOKER
BEGIN
	/* 
    		Created:	202212216@Casey.Huynh
		Task :		Match Monitor Arbitrage Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	202212216@Casey.Huynh: Created [Redmine ID: 179502]
            
		Param's Explanation (filtered by):            
		Example:		
        CALL CTS_DC_MatchMonitor_RuleArbitrage_Complete(@ip_LiveIndicator:=0,@ip_MaxSequenceID:=2,@ip_MatchID:=1,@ip_ScoreDiff:=1,@ip_BettypeID:=1,@ip_BetID:=0,@ip_HDP:=0.025
			,@ip_TransGroup:='[{"Reason":2,"TransIDList":"1,2","CustIDList":"1,2","OldGroupIDList":0}]');

	*/ 
   
    DECLARE lv_GroupID 					INT;
	DECLARE lv_Reason 					BOOLEAN;
    DECLARE lv_TransIDList 				LONGTEXT;
    DECLARE lv_CustIDList				LONGTEXT;
    DECLARE lv_OldGroupIDList			TEXT;
    DECLARE lv_NoOfOldGroupID			INT;
    DECLARE lv_EventDate 				DATE;
    DECLARE lv_LiveHomeScore			SMALLINT UNSIGNED;
    DECLARE lv_LiveAwayScore			SMALLINT UNSIGNED;
    DECLARE lv_TargetGroupID 				INT;
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
    DECLARE lv_LeagueName				VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE	lv_Sporttype				INT;
	DECLARE	lv_IsMajorLeague			INT;

 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
    CREATE TEMPORARY TABLE Temp_TransGroup
    (
			GroupID 			INT
        ,	Reason 				TINYINT
        ,	TransIDList 		LONGTEXT
        ,	CustIDList			LONGTEXT 
        ,	OldGroupIDList		TEXT
        
        ,	PRIMARY KEY Temp_TransGroup(GroupID)
    );
    
    INSERT IGNORE INTO Temp_TransGroup(GroupID, Reason, TransIDList, CustIDList, OldGroupIDList)
	SELECT  js.GroupID
		,	js.Reason
		,	js.TransIDList
		,	js.CustIDList
		,	js.OldGroupIDList
	FROM JSON_TABLE(ip_TransGroup,
					 "$[*]" COLUMNS(
								GroupID			INT PATH "$.GroupID" 
							,	Reason			TINYINT PATH "$.Reason" 
							,	TransIDList		LONGTEXT PATH "$.TransIDList"
							,	CustIDList		LONGTEXT PATH "$.CustIDList" 
							,	OldGroupIDList	TEXT PATH "$.OldGroupIDList" 
						)
				) AS js;     
    
    #======Update MatchMonitorDetails====================================  
	IF (ip_LiveIndicator = 0) THEN
		SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype,IsMajorLeague
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype, lv_IsMajorLeague
		FROM CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms
		WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.ScoreDiff = ip_ScoreDiff AND mms.HDP = ip_HDP
		LIMIT 1;	 
	END IF;

    #========UPDATE MatchMonitorDetails========================
    lp: LOOP 
		SET lv_GroupID = 0;
        SELECT GroupID, Reason, TransIDList, CustIDList, OldGroupIDList
        INTO lv_GroupID, lv_Reason, lv_TransIDList, lv_CustIDList, lv_OldGroupIDList
        FROM Temp_TransGroup
        ORDER BY GroupID LIMIT 1;        
          
       IF lv_GroupID =0 
        THEN			
            LEAVE lp; 
        END IF;
		
        CALL CTS_DC_Sys_SplitStringToTempItemTable(lv_OldGroupIDList,',','INT');

        SELECT Item INTO lv_TargetGroupID FROM TempItemTable WHERE Item <> 0 ORDER BY Item LIMIT 1;
        SELECT COUNT(1) INTO lv_NoOfOldGroupID FROM TempItemTable WHERE Item <> 0;
		SET lv_TargetGroupID = IFNULL(lv_TargetGroupID,0);
                
        IF(lv_NoOfOldGroupID = 0) # INSERT NEW GROUP
        THEN
			SELECT 	MAX(mmd.GroupID)
			INTO 	lv_TargetGroupID
			FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd
            WHERE 	mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.HDP = ip_HDP AND mmd.Reason = 1; 
			
            SET lv_TargetGroupID = IFNULL(lv_TargetGroupID,0);
			SET lv_TargetGroupID =  lv_TargetGroupID + 1;            

            INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, IsMajorLeague, LiveIndicator, ScoreDiff, HDP, BettypeID, BetID, EventDate, GroupID, LiveHomeScore, LiveAwayScore, ListCustID, ListTransID, Reason )
            VALUES(ip_MatchID, lv_IsMajorLeague, ip_LiveIndicator, ip_ScoreDiff, ip_HDP, ip_BettypeID, ip_BetID, lv_EventDate, lv_TargetGroupID, lv_LiveHomeScore, lv_LiveAwayScore, lv_CustIDList, lv_TransIDList, lv_Reason);          
 
        END IF; 

		IF (lv_NoOfOldGroupID = 1) THEN # UPDATE OLD GROUP         
			UPDATE IGNORE CTS_DataCenter.MatchMonitorDetails AS mmd 
			SET mmd.GroupID = lv_TargetGroupID, mmd.ListCustID = lv_CustIDList, mmd.ListTransID = lv_TransIDList, mmd.Reason = lv_Reason
			WHERE  mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.HDP = ip_HDP AND mmd.GroupID = lv_TargetGroupID  AND mmd.Reason = 1;
        END IF;        
  
        IF (lv_NoOfOldGroupID > 1) THEN # MERGE GROUP        
            DELETE mmd
            FROM CTS_DataCenter.MatchMonitorDetails AS mmd
				INNER JOIN TempItemTable AS tmpIt ON mmd.GroupID = tmpIt.Item
			WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.HDP = ip_HDP AND mmd.GroupID <> lv_TargetGroupID AND mmd.Reason = lv_Reason;
                    
			UPDATE IGNORE CTS_DataCenter.MatchMonitorDetails AS mmd
			SET mmd.GroupID = lv_TargetGroupID, mmd.ListCustID = lv_CustIDList, mmd.ListTransID = lv_TransIDList, mmd.Reason = lv_Reason
			WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.HDP = ip_HDP AND mmd.GroupID = lv_TargetGroupID  AND mmd.Reason = lv_Reason;
		END IF;
        
        DELETE tmptg
        FROM Temp_TransGroup AS tmptg WHERE GroupID = lv_GroupID;

        IF(ip_LiveIndicator = 0) THEN
			SET @sql = 	CONCAT("UPDATE CTS_DataCenter.MatchMonitorStagingArbitrageNonLive
            SET GroupID = ",lv_TargetGroupID,"
            WHERE TransID IN (",lv_TransIDList,")");
        END IF;

		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;  
    END LOOP;
    
    #========UPDATE MatchMonitor===================================    
 
    INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(MatchID, BettypeID, BetID, LiveIndicator, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, LeagueName, Sporttype, IsMajorLeague, Reason)
    SELECT	ip_MatchID, ip_BettypeID, ip_BetID, ip_LiveIndicator, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype, lv_IsMajorLeague
		,	mmd.Reason
	FROM CTS_DataCenter.MatchMonitorDetails AS mmd
	WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.Reason = lv_Reason;
	
END$$
DELIMITER ;
