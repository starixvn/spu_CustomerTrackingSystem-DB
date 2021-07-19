/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule`(
	IN ip_TimeGroupID INT
)
  SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
			-	20210719@Casey.Huynh: Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_Rule(ip_TimeGroupID);
			
	*/
    DECLARE lv_CustList LONGTEXT;
    DECLARE lv_MaxGroupID	INT DEFAULT 0;
	DECLARE lv_MinGroupID	INT DEFAULT 0;
    DECLARE lv_LoopID	INT DEFAULT 0;
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
    DECLARE lv_DetailsListTrans LONGTEXT;
    DECLARE lv_NewNoOfHedging INT;
    DECLARE lv_CurrentNoOfHedging INT;
    DECLARE lv_GroupID INT;
    DECLARE lv_DetailsGroupIDPre INT;    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
    CREATE TEMPORARY TABLE Temp_TransGroup(
			TransID			BIGINT UNSIGNED
		,	TransDate		DATETIME(3)
        ,	CustID			BIGINT UNSIGNED
        ,	Stake			DECIMAL
        , 	GroupID			BIGINT UNSIGNED
        ,	AssGroupID		INT
        ,	IsHedging		BOOLEAN        
        ,	PreTime			DATETIME(3)
        ,	TimeGroupID		INT        
        , 	LoopID			INT
		
        ,	PRIMARY KEY (TransID)
        ,	INDEX Temp_TransGroup_TimeGroupID(TimeGroupID)
        ,	INDEX Temp_TransGroup_TransDate(TransDate)
        ,	INDEX Temp_TransGroup_LoopID(LoopID,AssGroupID)
    );
 
    DROP TEMPORARY TABLE IF EXISTS Temp_AssGroup;
    CREATE TEMPORARY TABLE Temp_AssGroup(
			AssGroupID		INT
		,	ListCustID		LONGTEXT
        ,	ListTransID		LONGTEXT
        ,	IsHedging		INT
        ,	MinPreGroupID	INT
        ,	NoOfPreGroupID	INT
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssGroup;
	CREATE TEMPORARY TABLE Temp_AssGroup(
			AssGroupID INT
		,	MinTransID BIGINT UNSIGNED
        ,	MinTransDate BIGINT UNSIGNED
        ,	MaxTimeGroupID INT
        
        ,	PRIMARY KEY PK_Temp_AssGroup_AssGroupID(AssGroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RevmoveTimeGroup;
	CREATE TEMPORARY TABLE Temp_RevmoveTimeGroup(TimeGroupID INT PRIMARY KEY);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_OdlGroupID;
	CREATE TEMPORARY TABLE Temp_OdlGroupID(OldGroupID INT PRIMARY KEY);
    
    #====================================================================================
    
     #********GET CUST ASSOCIATION GROUP********	       
    INSERT INTO Temp_TransGroup(TransID, TransDate, CustID, Stake, GroupID, LoopID)
    SELECT	mms.TransID
		,	mms.TransDate
        ,	mms.CustID
        ,	mms.Stake
        ,	mms.GroupID
        ,	1 AS LoopID
    FROM CTS_DataCenter.MatchMonitorStaging AS mms
	WHERE mms.OriginGroupID = ip_TimeGroupID;
    
    IF NOT EXISTS(SELECT 1 FROM Temp_TransGroup)
    THEN
		LEAVE sp;
    END IF;
    
	SELECT 	MatchID
		,	LiveIndicator
        ,	TotalScore
        ,	BettypeID
        ,	EventDate
        ,	LiveHomeScore
        ,	LiveAwayScore
		,	EventStatus
        ,	HomeID
        ,	AwayID
        ,	KickOffTime
        ,	LeagueID
        ,	KickOffTime
    INTO 	lv_MatchID, lv_LiveIndicator, lv_TotalScore, lv_BettypeID, lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore
			, lv_EventStatus, lv_HomeID, lv_AwayID, lv_KickOffTime, lv_LeagueID, lv_KickOffTime
    FROM  	CTS_DataCenter.MatchMonitorStaging
    WHERE	OriginGroupID = ip_TimeGroupID 
    LIMIT 	1; 
    
	SET @i=1;
    SET lv_LoopID = 1;
    
	WHILE lv_LoopID IS NOT NULL
	DO   	  
		SELECT 	GROUP_CONCAT(DISTINCT CustID)
		INTO	lv_CustList
		FROM	Temp_TransGroup AS tmpTg
		WHERE	tmpTg.LoopID = lv_LoopID;        
        
		CALL CTS_DC_Association_GetGroup(lv_CustList); #Return CustAssociationGroup Into Temporary table "Temp_Group" 

        UPDATE Temp_TransGroup AS tmpTg
			INNER JOIN Temp_Group AS tmpGp ON tmpTg.CustID = tmpGp.CustID
        SET tmpTg.AssGroupID = tmpGp.GroupID, tmpTg.IsHedging = tmpGp.IsHedging
        WHERE	tmpTg.LoopID = lv_LoopID;
        
        #=====REMOVE TRANS NOT HAVE GROUP=========        
        DELETE 	tmpTg 
        FROM 	Temp_TransGroup AS tmpTg
		WHERE 	tmpTg.AssGroupID IS NULL
				AND tmpTg.LoopID = lv_LoopID;  

        #==================================
        TRUNCATE TABLE Temp_AssGroup;
        
		INSERT INTO Temp_AssGroup(AssGroupID, MinTransID, MinTransDate, MaxTimeGroupID)
		SELECT 	AssGroupID
			,	MIN(TransID)
            ,	MIN(TransDate)
            ,	MAX(TimeGroupID)
		FROM	Temp_TransGroup AS  tmpTg
        WHERE	tmpTg.LoopID = lv_LoopID
		GROUP BY AssGroupID;
        
		SET @TimeGroupID=0;
		SET @PreTime=NULL;
		SET @GroupOrder = 0; 
        
		UPDATE Temp_TransGroup AS tmpTg
			INNER JOIN Temp_AssGroup AS tmpTa ON  tmpTg.AssGroupID = tmpTa.AssGroupID
		SET	tmpTg.PreTime = IF(tmpTg.TransID = tmpTa.MinTransID, @PreTime:=tmpTa.MinTransDate, @PreTime) 	
			, 	tmpTg.TimeGroupID	= IF(tmpTg.TransID = tmpTa.MinTransID, @TimeGroupID:=@TimeGroupID + 1
										, IF(TIMESTAMPDIFF(SECOND,@PreTime, @PreTime:=tmpTg.TransDate) > 180 , @TimeGroupID:=@TimeGroupID +1 
										, @TimeGroupID))
		WHERE tmpTg.LoopID = lv_LoopID;
        
        #==================================================
        SET @i=IFNULL((SELECT tmpTg.TimeGroupID FROM Temp_TransGroup AS tmpTg WHERE tmpTg.LoopID = lv_LoopID AND tmpTg.TimeGroupID > 1 LIMIT 1),1);
      
		#=====REMOVE TRANS GROUP NOT MATCH CONDITION TOTAL STAKE AND NUMBER OF CUST=========		
        TRUNCATE TABLE Temp_RevmoveTimeGroup;
        
        INSERT INTO Temp_RevmoveTimeGroup(TimeGroupID)
        SELECT tmpTg.TimeGroupID
        FROM Temp_TransGroup AS tmpTg        
        WHERE tmpTg.LoopID = lv_LoopID AND tmpTg.TimeGroupID IS NOT NULL
        GROUP BY tmpTg.TimeGroupID
        HAVING SUM(Stake) < 500 OR COUNT(DISTINCT CustID) < 2;

        DELETE tmpTg
        FROM Temp_TransGroup AS tmpTg
			INNER JOIN Temp_RevmoveTimeGroup AS tmpRv ON tmpTg.TimeGroupID = tmpRv.TimeGroupID
		WHERE tmpTg.LoopID = lv_LoopID;
        #===================================  
		
        IF @i = 1 AND EXISTS (SELECT 1 FROM Temp_TransGroup)
        THEN 			
			#===GET Current GroupID=====
            TRUNCATE TABLE Temp_OdlGroupID;
            
            INSERT INTO Temp_OdlGroupID(OldGroupID)
			SELECT DISTINCT tmpTg.GroupID
            FROM Temp_TransGroup AS tmpTg
            WHERE tmpTg.LoopID = lv_LoopID AND tmpTg.GroupID IS NOT NULL ; 
            
			DELETE	mmd
			FROM	CTS_DataCenter.MatchMonitorDetails AS mmd
				INNER JOIN Temp_OdlGroupID AS tmp ON mmd.GroupID = tmp.OldGroupID 
			WHERE	mmd.MatchID = lv_MatchID AND  mmd.LiveIndicator = lv_LiveIndicator AND mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID;
			
			SELECT 	MIN(OldGroupID)
			INTO 	lv_GroupID
			FROM 	Temp_OdlGroupID;
			
			IF lv_GroupID IS NULL THEN
				SELECT MAX(GroupID) + 1
				INTO lv_GroupID
				FROM CTS_DataCenter.MatchMonitorDetails AS mmd
				WHERE mmd.MatchID = lv_MatchID AND  mmd.LiveIndicator = lv_LiveIndicator AND mmd.TotalScore = lv_TotalScore AND mmd.BettypeID = lv_BettypeID;
			END IF;
			
			SET lv_GroupID = IFNULL(lv_GroupID,1);
			
			UPDATE Temp_TransGroup AS tmpTg
			SET 	tmpTg.GroupID = lv_GroupID
			WHERE	tmpTg.LoopID = lv_LoopID;
		   
			INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, BettypeID, EventDate, LiveIndicator
						, TotalScore, LiveHomeScore, LiveAwayScore, GroupID, IsHedging, ListCustID, ListTransID, LastModifiedTime)
			SELECT	lv_MatchID
				,	lv_BettypeID
				,	lv_EventDate
				,	lv_LiveIndicator					
				,	lv_TotalScore
				,	lv_LiveHomeScore
				,	lv_LiveAwayScore
				,	lv_GroupID
				,	MAX(tmpTg.IsHedging)
				,	GROUP_CONCAT(DISTINCT tmpTg.CustID) AS ListCustID
				,	GROUP_CONCAT(tmpTg.TransID) AS ListTransID
				,	CURRENT_TIMESTAMP(3)
			FROM	Temp_TransGroup AS tmpTg                
			WHERE	tmpTg.LoopID = lv_LoopID;

			SELECT  COUNT(DISTINCT mm.IsHedging), MIN(mm.IsHedging), MAX(mm.IsHedging)
			INTO @NoOfIsHedging, @MinIsHedging, @MaxIsHedging
			FROM CTS_DataCenter.MatchMonitor AS mm 
			WHERE mm.MatchID = lv_MatchID AND mm.BettypeID = lv_BettypeID;
			
			SELECT COUNT(DISTINCT mmd.IsHedging), MIN(mmd.IsHedging), MAX(mmd.IsHedging)
			INTO @NoOfIsHedgingDetails, @MinIsHedgingDetails, @MaxIsHedgingDetails
			FROM CTS_DataCenter.MatchMonitorDetails AS mmd
			WHERE mmd.MatchID = lv_MatchID AND mmd.BettypeID = lv_BettypeID;
			
			IF(@NoOfIsHedging < @NoOfIsHedgingDetails) 
			THEN                
				INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(IsHedging, MatchID, BettypeID, EventDate, EventStatus, KickOffTime, HomeID, AwayID,LeagueID,LastModifiedTime)
				SELECT 	(CASE WHEN @MinIsHedging = 0 THEN 1 ELSE 0 END) AS IsHedging
						, lv_MatchID, lv_BettypeID, lv_EventDate, lv_EventStatus , lv_KickOffTime, lv_HomeID, lv_AwayID, lv_LeagueID, CURRENT_TIMESTAMP(3) ;
			END IF;
			
			IF(@NoOfIsHedging = @NoOfIsHedgingDetails AND @MinIsHedging <> @MinIsHedgingDetails) 
			THEN                
				UPDATE CTS_DataCenter.MatchMonitor AS mm 
				SET mm.IsHedging = @MinIsHedgingDetails, mm.LastModifiedTime = CURRENT_TIMESTAMP(3)
				WHERE mm.MatchID = lv_MatchID AND mm.BettypeID = lv_BettypeID;
			END IF;
			
			IF(@NoOfIsHedging > @NoOfIsHedgingDetails) 
			THEN                
				DELETE  mm
				FROM	CTS_DataCenter.MatchMonitor AS mm 
				WHERE 	mm.MatchID = lv_MatchID AND mm.BettypeID = lv_BettypeID AND mm.IsHedging <> @MinIsHedgingDetails ;
			END IF; 
            
			UPDATE CTS_DataCenter.MatchMonitorStaging AS mms
            INNER JOIN Temp_TransGroup AS tmpTg ON mms.TransID = tmpTg.TransID
            SET mms.GroupID = tmpTg.GroupID;
            
			DELETE tmpTg
			FROM Temp_TransGroup AS tmpTg
			WHERE tmpTg.LoopID = lv_LoopID;            
        ELSE
			UPDATE Temp_TransGroup AS tmpTg
            SET tmpTg.LoopID = tmpTg.TimeGroupID, tmpTg.AssGroupID = NULL, tmpTg.IsHedging = NULL
            WHERE tmpTg.LoopID = lv_LoopID;
        END IF;
        #============================================================
        SET lv_LoopID = (SELECT TimeGroupID FROM Temp_TransGroup LIMIT 1);       
        #===========================================    
        
	END WHILE;

END$$
DELIMITER ;
