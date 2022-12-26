/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleGroupBetting_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleGroupBetting_Complete`(
		IN ip_LiveIndicator BOOLEAN
	,	IN ip_MaxSequenceID	BIGINT UNSIGNED
	, 	IN ip_MatchID		INT
    , 	IN ip_ScoreDiff		INT 
    , 	IN ip_BettypeID		INT
    ,	IN ip_BetID			BIGINT
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
            -	20211213@Casey.Huynh: Enhance MM, Add column LeagueName [Redmine ID: 165606]
			-	20220110@Casey.Huynh: Enhance MM, Add SportType, Betteam, BetID [Redmine ID: 166986]
            -	20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            - 	20220830@Casey.Huynh: New Category for Classify Group Betting [Redmine ID: #176976]
            -	202200929@Casey.Huynh: Seperate By Sport [Redmine ID: #178310]
            - 	202201021@Casey.Huynh: Group By Betteam [Redmine ID: #179439]
            -	20221205@Casey.Huynh: Rename Table [Redmine ID: #179502]
		Param's Explanation (filtered by):			

		Example:
			CALL CTS_DC_MatchMonitor_RuleGroupBetting_Complete(1,114089577333,48310358,0,1,0,'[{"GroupID":4,"Reason":0,"TransList":"114089577333,114089576830","CustIDList":"55706032,55895790","OldGroupIDList":"0"}]');
			
		*/
	DECLARE CONS_LOG 					TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
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
    DECLARE	lv_KickOffTime 				DATETIME;
    DECLARE	lv_EventStatus 				VARCHAR(50);
    DECLARE lv_HomeID 					INT UNSIGNED;
    DECLARE lv_AwayID 					INT UNSIGNED;
    DECLARE lv_LeagueID					INT UNSIGNED;
    DECLARE lv_LeagueName				VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE	lv_Sporttype				INT;
	
	#==================LOG=======================================================
	DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleGroupBetting_Complete';
    IF CONS_LOG = 1 THEN
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText, JsonString1)
		SELECT lv_SPName, CURRENT_TIMESTAMP(),CONCAT('ip_LiveIndicator:',ip_LiveIndicator,',ip_MaxSequenceID:',ip_MaxSequenceID
			,',ip_MatchID:',ip_MatchID,',ip_ScoreDiff:',ip_ScoreDiff,',ip_BettypeID:',',ip_BetID:',ip_BetID),ip_TransGroup; 
	END IF;
    #==================LOG=======================================================
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

    IF (ip_LiveIndicator = 1) THEN
		SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
		FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
		WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.ScoreDiff = ip_ScoreDiff
		LIMIT 1;
	END IF;

	IF (ip_LiveIndicator = 0) THEN
		SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
		FROM CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms
		WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.ScoreDiff = ip_ScoreDiff
		LIMIT 1;	 
	END IF;
	#=======REASON=================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Reason;
	CREATE TEMPORARY TABLE Temp_Reason(Reason INT PRIMARY KEY);
    IF lv_Sporttype = 1 THEN
		INSERT INTO Temp_Reason(Reason)
        VALUES	(0)
			,	(2);
	ELSE
		INSERT INTO Temp_Reason(Reason)
        VALUES	(0)
			,	(1)
            ,	(2);
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
				INNER JOIN Temp_Reason AS tmpR ON mmd.Reason = tmpR.Reason
            WHERE 	mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff ; 
			
            SET lv_TargetGroupID = IFNULL(lv_TargetGroupID,0);
			SET lv_TargetGroupID =  lv_TargetGroupID + 1;            
   
            INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, LiveIndicator, ScoreDiff, BettypeID, BetID, EventDate, GroupID, LiveHomeScore, LiveAwayScore, ListCustID, ListTransID, Reason )
            VALUES(ip_MatchID, ip_LiveIndicator, ip_ScoreDiff, ip_BettypeID, ip_BetID, lv_EventDate, lv_TargetGroupID, lv_LiveHomeScore, lv_LiveAwayScore, lv_CustIDList, lv_TransIDList, lv_Reason);          
            
        END IF; 
    
		IF (lv_NoOfOldGroupID = 1) THEN # UPDATE OLD GROUP	        
			UPDATE IGNORE CTS_DataCenter.MatchMonitorDetails AS mmd 
				INNER JOIN Temp_Reason AS tmpR ON mmd.Reason = tmpR.Reason
			SET mmd.GroupID = lv_TargetGroupID, mmd.ListCustID = lv_CustIDList, mmd.ListTransID = lv_TransIDList, mmd.Reason = lv_Reason
			WHERE  mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.GroupID = lv_TargetGroupID;
		END IF;        
        
        IF (lv_NoOfOldGroupID > 1) THEN # MERGE GROUP        
            DELETE mmd
            FROM CTS_DataCenter.MatchMonitorDetails AS mmd
				INNER JOIN Temp_Reason AS tmpR ON mmd.Reason = tmpR.Reason
				INNER JOIN TempItemTable AS tmpIt ON mmd.GroupID = tmpIt.Item
			WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.GroupID <> lv_TargetGroupID;
                    
			UPDATE IGNORE CTS_DataCenter.MatchMonitorDetails AS mmd
				INNER JOIN Temp_Reason AS tmpR ON mmd.Reason = tmpR.Reason
			SET mmd.GroupID = lv_TargetGroupID, mmd.ListCustID = lv_CustIDList, mmd.ListTransID = lv_TransIDList, mmd.Reason = lv_Reason
			WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID AND mmd.ScoreDiff = ip_ScoreDiff AND mmd.GroupID = lv_TargetGroupID;
		END IF;

        DELETE tmptg
        FROM Temp_TransGroup AS tmptg WHERE GroupID = lv_GroupID;

        IF(ip_LiveIndicator = 1) THEN
			SET @sql = 	CONCAT("UPDATE CTS_DataCenter.MatchMonitorStagingGroupBettingLive
            SET GroupID = ",lv_TargetGroupID,"
            WHERE TransID IN (",lv_TransIDList,")");    
		ELSE		
			SET @sql = 	CONCAT("UPDATE CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive
            SET GroupID = ",lv_TargetGroupID,"
            WHERE TransID IN (",lv_TransIDList,")");
        END IF;

		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;  
    END LOOP;

    #========UPDATE MatchMonitor===================================
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitor_Reason;
    CREATE TEMPORARY TABLE Temp_MatchMonitor_Reason(
		Reason TINYINT PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorDetails_Reason;
    CREATE TEMPORARY TABLE Temp_MatchMonitorDetails_Reason(
		Reason TINYINT PRIMARY KEY
    );

    INSERT INTO Temp_MatchMonitor_Reason(Reason)
    SELECT DISTINCT mm.Reason
    FROM CTS_DataCenter.MatchMonitor AS mm
		INNER JOIN Temp_Reason AS tmpR ON mm.Reason = tmpR.Reason
    WHERE mm.LiveIndicator = ip_LiveIndicator AND mm.MatchID = ip_MatchID AND mm.BettypeID = ip_BettypeID AND mm.BetID = ip_BetID; 
       
    INSERT INTO Temp_MatchMonitorDetails_Reason(Reason)
    SELECT DISTINCT mmd.Reason
    FROM CTS_DataCenter.MatchMonitorDetails AS mmd
		INNER JOIN Temp_Reason AS tmpR ON mmd.Reason = tmpR.Reason
    WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID;           
    
	DELETE mm
	FROM CTS_DataCenter.MatchMonitor AS mm
		INNER JOIN Temp_Reason AS tmpR ON mm.Reason = tmpR.Reason
		LEFT JOIN Temp_MatchMonitorDetails_Reason AS tmpMmd ON mm.Reason = tmpMmd.Reason
	WHERE mm.LiveIndicator = ip_LiveIndicator AND mm.MatchID = ip_MatchID AND mm.BettypeID = ip_BettypeID AND mm.BetID = ip_BetID AND tmpMmd.Reason IS NULL;    
    
    INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(MatchID, BettypeID, BetID, LiveIndicator, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, LeagueName, Sporttype, Reason)
    SELECT	ip_MatchID, ip_BettypeID, ip_BetID, ip_LiveIndicator, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
		,	mmd.Reason
	FROM CTS_DataCenter.MatchMonitorDetails AS mmd
		INNER JOIN Temp_Reason AS tmpR ON mmd.Reason = tmpR.Reason
		LEFT JOIN Temp_MatchMonitor_Reason AS tmpMm ON mmd.Reason = tmpMm.Reason
	WHERE mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID AND mmd.BetID = ip_BetID;
    
END$$
DELIMITER ;
