/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleGroupBetting_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleGroupBetting_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_ScoreDiff			INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_Betteam			VARCHAR(10)
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
    
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule Process
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: 	Created [Redmine ID: 152883]
			-	20210719@Casey.Huynh: 	Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
			-	20210830@Casey.Huynh: 	Update Rule seperate Live and NonLive and move to Slave [Redmine ID: 159195]
			-	20211019@Aries.Nguyen: 	Use FEDERATED  table [Redmine ID: 163400]
			-	20211102@Aries.Nguyen: 	Fix FEDERATED connection fail[Redmine ID: 163400]
			-	20211111@Casey.Huynh: 	Fix Issue Trans of the same Cust not merge Group [Redmine ID: 164558]
			-	20220110@Casey.Huynh: 	Enhance MM, Add SportType, Betteam, BetID [Redmine ID: 166986]
			-	20220217@Casey.Huynh: 	Enhance MM, Update TO >= 1000 [Redmine ID: 168736]
			- 	20220422@Irena.Vo: 	Mapping Is Hedging Reason (MM) from table CustomerCategory [Redmine ID: #170468]
			-	20220815@Casey.Huynh: 	Scale Out DB [Redmine ID: #176472]
			- 	20220830@Casey.Huynh: 	New Category for Classify Group Betting [Redmine ID: #176976]
			-	202200929@Casey.Huynh: 	Seperate By Sport [Redmine ID: #178310]
			-	20221021@Casey.Huynh: 	Fixed Clean Data Staging [Redmine ID: #179427]
			-	20221027@Casey.Huynh: 	Seperate pool Staging [RedmineID: 179439]
			-	20221205@Casey.Huynh: 	Rename Table and remove (Arbitrage,Hedging) [Redmine ID: #179502]
            		-	20230221@Casey.Huynh: 	Update Rule, The same Choice [Redmine ID: #184041]
            		- 	20230112@Victoria.Le: 	Modify SPs due to restructure AssociationByAI [Redmine ID: #181994]
			
		Param's Explanation (filtered by):	
		Example:
			- CALL CTS_DC_MatchMonitor_RuleGroupBetting_Process(1,113171940189,22081995,1,1,0,'a');
			
	*/
    DECLARE CONS_LOG 			TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
    DECLARE CONST_RULE_GROUPID 	INT DEFAULT 1;
    
    DECLARE lv_TimeCustID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MinTransDate DATETIME(3);
    DECLARE lv_MaxTransDate DATETIME(3);
    DECLARE lv_TimeGroupID INT DEFAULT 0;
    DECLARE lv_Stake DECIMAL(20,4);
    DECLARE lv_TransID BIGINT UNSIGNED;
    DECLARE lv_CustID BIGINT UNSIGNED;
    DECLARE lv_CTSCustID BIGINT UNSIGNED;
    DECLARE lv_GroupID INT DEFAULT 1;
    DECLARE lv_IsHedging INT DEFAULT 0;
    DECLARE lv_CustIDList LONGTEXT;
    DECLARE lv_ClassifyHighStake DECIMAL(20,4) DEFAULT 50;
    DECLARE lv_Rule_TotalStake DECIMAL(20,4);
    DECLARE lv_Rule_TimeStep SMALLINT;
    DECLARE lv_SportType SMALLINT;
    DECLARE lv_Rule_Reason INT DEFAULT 0; #0: Group Betting 
    
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleGroupBetting_Process';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator,',@ip_MaxSequenceID:=',ip_MaxSequenceID,',@ip_MatchID:=',ip_MatchID
		,@ip_ScoreDiff:=',ip_ScoreDiff,',@ip_BettypeID:=',ip_BettypeID,',@ip_BetID:=',ip_BetID');
    END IF;
    #=================================================================================    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_StagingTrans;
    CREATE TEMPORARY TABLE Temp_StagingTrans(
			TransID		BIGINT UNSIGNED NOT NULL
		,	SequenceID	BIGINT UNSIGNED NOT NULL
        ,	TransDate	DATETIME(3)  NOT NULL
        ,	CustID		BIGINT  NOT NULL
        ,	OldGroupID	INT 
        ,	Stake		DECIMAL(20,4)
        ,	Betteam		VARCHAR(10)
        
        ,	PRIMARY KEY PK_Temp_StagingTrans(CustID, TransDate, Stake, TransID)
        ,	INDEX IX_Temp_StagingTrans(TransID)
        ,	INDEX IX_Temp_StagingTransSequenceID(SequenceID)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_StagingTrans02;
    CREATE TEMPORARY TABLE Temp_StagingTrans02(
			TransID		BIGINT UNSIGNED NOT NULL
		,	SequenceID	BIGINT UNSIGNED NOT NULL
        ,	TransDate	DATETIME(3)  NOT NULL
        ,	CustID		BIGINT  NOT NULL
        ,	OldGroupID	INT 
        ,	Stake		DECIMAL(20,4)
        ,	Betteam		VARCHAR(10)
        
        ,	PRIMARY KEY PK_Temp_StagingTrans02(CustID, TransDate, Stake, TransID)
        ,	INDEX IX_Temp_StagingTrans02_TransID(TransID)
        ,	INDEX IX_Temp_StagingTransSequenceID(SequenceID)
        ,	INDEX IX_Temp_StagingTrans02_Betteam(Betteam)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustTimeGroup;
    CREATE TEMPORARY TABLE Temp_CustTimeGroup(
			TransID		BIGINT UNSIGNED 
        ,	TransDate	DATETIME(3)
        ,	CustID		BIGINT
        ,	Stake		DECIMAL(20,4)
        ,	GroupID		DECIMAL(20,4)
        
        ,	PRIMARY KEY PK_Temp_CustTimeGroup(CustID, TransDate, Stake, TransID)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustTime01;
    CREATE TEMPORARY TABLE Temp_CustTime01(
			CustID		BIGINT UNSIGNED
		,	MinTransDate	DATETIME(3)
        ,	MaxTransDate	DATETIME(3)
        
        ,	PRIMARY KEY Temp_CustTime01(CustID, MinTransDate, MaxTransDate)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustTime02;
    CREATE TEMPORARY TABLE Temp_CustTime02 LIKE Temp_CustTime01;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation01;
	CREATE TEMPORARY TABLE Temp_CustAssociation01(
			CustID_1		BIGINT UNSIGNED
		,	MinTransDate_1	DATETIME(3)
		,	MaxTransDate_1	DATETIME(3)
        ,	CustID_2		BIGINT UNSIGNED
		,	MinTransDate_2	DATETIME(3)
		,	MaxTransDate_2	DATETIME(3)
        
        ,	INDEX IX_Temp_CustAssociation01(CustID_1, MinTransDate_1, CustID_2, MinTransDate_2)        
	);
    
        
	DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
	CREATE TEMPORARY TABLE Temp_TransGroup(
			CustID			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED
		,	MinTransDate	DATETIME(3)
		,	MaxTransDate	DATETIME(3)
		,	GroupID			INT
        , 	Reason			INT DEFAULT 0        
        
        ,	PRIMARY KEY PK_Temp_TransGroup(CustID, MinTransDate)
	);    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup02;
	CREATE TEMPORARY TABLE Temp_TransGroup02(
			CustID			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED
		,	MinTransDate	DATETIME(3)
		,	MaxTransDate	DATETIME(3)
		,	GroupID			INT
        , 	Reason			INT DEFAULT 0        
        
        ,	PRIMARY KEY PK_Temp_TransGroup(CustID, MinTransDate)
	);
    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ResultGroup;
    CREATE TEMPORARY TABLE Temp_ResultGroup(
			GroupID					INT PRIMARY KEY
		,	Reason					INT
        ,	TransIDList				LONGTEXT
        ,	CustIDList				LONGTEXT
        ,	OldGroupIDList			VARCHAR(500)
        ,	HighStakeLicCustList 	LONGTEXT
        ,	LicenseeCustTotal		INT
    );	
	
    
    #-------------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE 		Temp_Association (
			CTSCustID_1 		BIGINT UNSIGNED DEFAULT 0
		 , 	CustID_1 			BIGINT UNSIGNED DEFAULT 0
		 ,	CTSCustID_2 	    BIGINT UNSIGNED DEFAULT 0
		 ,  CustID_2 	    	BIGINT UNSIGNED DEFAULT 0
		 ,  AssociationType		SMALLINT
		 ,	INDEX IX_Temp_Association_CTSCustID1_CTSCustID2(CTSCustID_1,CTSCustID_2)
		 ,	INDEX IX_Temp_Association_CustID1_CustID2(CustID_1,CustID_2)
         ,	INDEX IX_Temp_Association_CustID2(CustID_2)
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
	CREATE TEMPORARY TABLE 		Temp_CustAssociation (
			CustID_1 			BIGINT UNSIGNED
		 ,	CustID_2 	    	BIGINT UNSIGNED
		 ,	PRIMARY KEY IX_Temp_Association_CTSCustID1_CTSCustID2(CustID_1, CustID_2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Remove;
	CREATE TEMPORARY TABLE 		Temp_Association_Remove (
			CTSCustID_1 		BIGINT UNSIGNED 
		 ,	CTSCustID_2 	    BIGINT UNSIGNED
		 ,	INDEX IX_Temp_Association_CTSCustID_1(CTSCustID_1)
		 ,	INDEX IX_Temp_Association_CTSCustID_2(CTSCustID_2)
	);     
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			CTSCustID 			BIGINT UNSIGNED 
		 ,	CustID 				BIGINT UNSIGNED PRIMARY KEY
		 ,	INDEX IX_Temp_Cust_CTSCustID(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
	CREATE TEMPORARY TABLE 		Temp_CustDevice (
			CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCust_Group;
	CREATE TEMPORARY TABLE 		Temp_DeviceCust_Group (
			DCSDeviceID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust			INT
	);
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupHedging;
	CREATE TEMPORARY TABLE 	Temp_GroupHedging (
			GroupID	INT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
	CREATE TEMPORARY TABLE 		Temp_CustInfo (
		 	CustID 			BIGINT UNSIGNED 
	);
    
    #******** GET STAGING TRANS ******************************************************************
    #*********************************************************************************************    
    
    IF (ip_LiveIndicator = 1)
    THEN
		SELECT mms.SportType INTO lv_SportType FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms WHERE mms.MatchID = ip_MatchID LIMIT 1;
        
		INSERT INTO Temp_StagingTrans(TransID, SequenceID, TransDate, CustID, OldGroupID, Stake, Betteam)
        SELECT	mms.TransID
			,	mms.SequenceID
			,	mms.TransDate
            ,	mms.CustID
            ,	mms.GroupID
            ,	mms.Stake
            ,	mms.Betteam
		FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
        WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.ScoreDiff = ip_ScoreDiff AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam;
        
	ELSE 
		SELECT mms.SportType INTO lv_SportType FROM CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms WHERE mms.MatchID = ip_MatchID LIMIT 1;
	  
		INSERT INTO Temp_StagingTrans(TransID, SequenceID, TransDate, CustID, OldGroupID, Stake,Betteam)
        SELECT	mms.TransID
			,	mms.SequenceID
			,	mms.TransDate
            ,	mms.CustID
            ,	mms.GroupID
            ,	mms.Stake
            ,	mms.Betteam
		FROM CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms
        WHERE  mms.SequenceID <= ip_MaxSequenceID AND	mms.MatchID = ip_MatchID AND mms.ScoreDiff = ip_ScoreDiff AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam;        
    END IF;
    
	SELECT rs.TotalStake, rs.TimeStep, rs.Reason
    INTO lv_Rule_TotalStake, lv_Rule_TimeStep, lv_Rule_Reason
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS rs
    WHERE rs.RuleGroupID = CONST_RULE_GROUPID AND rs.SportType = lv_SportType AND rs.RuleStatus = 1;
    
    INSERT INTO Temp_StagingTrans02 SELECT * FROM Temp_StagingTrans;
    
    #******** CACULATE TIME GROUP BY CUSTID AND IN 3 MINUTES *****************************************************************
    #*************************************************************************************************************************   
    WHILE EXISTS ( SELECT 1 FROM Temp_StagingTrans)
    DO
		SET lv_TimeGroupID = lv_TimeGroupID + 1;
        
		SELECT tmpTs.CustID, tmpTs.TransDate, Stake, TransID
		INTO lv_TimeCustID, lv_MinTransDate, lv_Stake, lv_TransID
		FROM Temp_StagingTrans  AS tmpTs
		ORDER BY CustID, TransDate
		LIMIT 1;
        
        INSERT INTO Temp_CustTimeGroup(CustID, TransDate, Stake, TransID, GroupID)
		WITH RECURSIVE CTE_Group AS ( 
			SELECT	lv_TimeCustID AS CustID
				,	lv_MinTransDate AS MinTransDate
                ,	lv_MinTransDate AS TransDate
				,	lv_Stake AS Stake
                ,	lv_TransID AS TransID
			UNION
			SELECT	tmpSt.CustID
				,	CTE_Group.MinTransDate
                ,	tmpSt.TransDate
                ,  	tmpSt.Stake
                ,	tmpSt.TransID
			FROM Temp_StagingTrans  AS tmpSt
				JOIN CTE_Group ON CTE_Group.CustID = tmpSt.CustID AND TIMESTAMPDIFF(SECOND, CTE_Group.MinTransDate, tmpSt.TransDate) <= lv_Rule_TimeStep
		) 
		SELECT CustID, TransDate, Stake, TransID, lv_TimeGroupID FROM CTE_Group;
        
        DELETE tmpSt
        FROM Temp_StagingTrans AS tmpSt
        INNER JOIN Temp_CustTimeGroup AS ctg ON ctg.TransID = tmpSt.TransID;
	
    END WHILE;
        
    INSERT INTO Temp_CustTime01(CustID, MinTransDate, MaxTransDate)
    SELECT	tmpCt.CustID
		,	MIN(tmpCt.TransDate)
        ,	MAX(tmpCt.TransDate)
    FROM Temp_CustTimeGroup AS tmpCt
    GROUP BY tmpCt.CustID, tmpCt.GroupID;
    
    #******** GET Association *****************************************************************
    #******************************************************************************************
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID)
	SELECT DISTINCT IFNULL(cus.CTSCustID,0), tmp.CustID
	FROM Temp_CustTimeGroup AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CustID = cus.CustID AND cus.CustSubID = 0;    
    
	#------------Get association Device ------------------#
	INSERT IGNORE INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
	SELECT 	cus.CTSCustID 
		, 	dv.DCSDeviceID
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;

	INSERT INTO Temp_DeviceCust_Group(DCSDeviceID, TotalCust)
	SELECT 	DCSDeviceID
		, 	COUNT(1) AS TotalCust
	FROM Temp_CustDevice 
	GROUP BY DCSDeviceID;

	DELETE tmp
    FROM Temp_CustDevice AS tmp
	WHERE tmp.DCSDeviceID IN (SELECT DCSDeviceID FROM Temp_DeviceCust_Group WHERE TotalCust = 1);

	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Duplicate;
	CREATE TEMPORARY TABLE Temp_CustDevice_Duplicate LIKE Temp_CustDevice;
    
	INSERT INTO Temp_CustDevice_Duplicate 
	SELECT * FROM Temp_CustDevice;

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT DISTINCT dv.CTSCustID,  dv1.CTSCustID  , 1
	FROM Temp_CustDevice AS dv
		INNER JOIN Temp_CustDevice_Duplicate AS dv1 ON dv.DCSDeviceID = dv1.DCSDeviceID AND dv.CTSCustID != dv1.CTSCustID;

	#------------Get association manual ------------------
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Duplicate;
	CREATE TEMPORARY TABLE Temp_Cust_Duplicate LIKE Temp_Cust;
    
	INSERT INTO Temp_Cust_Duplicate
	SELECT * FROM Temp_Cust;
    
	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  cus.CTSCustID,  ma.ToCTSCustID, 2
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.ToCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  ma.ToCTSCustID, cus.CTSCustID, 2
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.ToCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  cus.CTSCustID,  ma.FromCTSCustID, 2
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.FromCTSCustID);

	INSERT IGNORE INTO Temp_Association(CTSCustID_1, CTSCustID_2, AssociationType)
	SELECT  ma.FromCTSCustID, cus.CTSCustID,   2
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CTSCustID = ma.FromCTSCustID);

	#----------------------Get association by AI-------------------------------
	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT  cus.CustID,  ai.ToCustID, 3
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID
															AND ai.AssType = 2
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT   ai.ToCustID, cus.CustID,  3
	FROM Temp_Cust AS cus
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = cus.CustID
															AND ai.AssType = 2
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.ToCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT  cus.CustID,  ai.FromCustID, 3
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID
															AND ai.AssType = 2
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.FromCustID);

	INSERT IGNORE INTO Temp_Association(CustID_1, CustID_2, AssociationType)
	SELECT   ai.FromCustID, cus.CustID,  3
	FROM Temp_Cust AS cus 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = cus.CustID
															AND ai.AssType = 2
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS tic WHERE tic.CustID = ai.FromCustID);
	
	#-----------------------------------------------------------Update CustId, CTSCustID of Association table------------------------------------------------
	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CustID_1 = cus.CustID
	SET ass.CTSCustID_1 = cus.CTSCustID
	WHERE ass.CTSCustID_1 = 0 ;

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CustID_2 = cus.CustID
	SET ass.CTSCustID_2 = cus.CTSCustID
	WHERE ass.CTSCustID_2 = 0;

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CTSCustID_1 = cus.CTSCustID
	SET ass.CustID_1 = cus.CustID
	WHERE ass.CustID_1 = 0;

	UPDATE Temp_Association AS ass
	INNER JOIN Temp_Cust AS cus ON ass.CTSCustID_2 = cus.CTSCustID
	SET ass.CustID_2 = cus.CustID
	WHERE ass.CustID_2 = 0;

	#-----------------------------------------------------------------Handle Association Remove-------------------------------------------------------
	INSERT INTO Temp_Association_Remove(CTSCustID_1, CTSCustID_2)
	SELECT FromCTSCustID, ToCTSCustID 
	FROM CTS_DataCenter.AssociationRemove AS rm
	WHERE EXISTS (SELECT 1 FROM Temp_Association AS ass WHERE  rm.FromCTSCustID = ass.CTSCustID_1 AND rm.ToCTSCustID = ass.CTSCustID_2);

	INSERT INTO Temp_Association_Remove(CTSCustID_1, CTSCustID_2)
	SELECT FromCTSCustID, ToCTSCustID 
	FROM CTS_DataCenter.AssociationRemove AS rm
	WHERE EXISTS (SELECT 1 FROM Temp_Association AS ass WHERE  rm.FromCTSCustID = ass.CTSCustID_2 AND rm.ToCTSCustID = ass.CTSCustID_1);

	DELETE ass
    FROM Temp_Association AS ass
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Remove AS rm WHERE  rm.CTSCustID_1 = ass.CTSCustID_1 AND rm.CTSCustID_2 = ass.CTSCustID_2);

	DELETE ass
    FROM Temp_Association AS ass
	WHERE EXISTS (SELECT 1 FROM Temp_Association_Remove AS rm WHERE  rm.CTSCustID_1 = ass.CTSCustID_2 AND rm.CTSCustID_2 = ass.CTSCustID_1);

    INSERT INTO Temp_CustTime02 SELECT * FROM Temp_CustTime01;	

    INSERT IGNORE INTO Temp_CustAssociation(CustID_1, CustID_2)
    SELECT DISTINCT CustID_2, CustID_1
    FROM Temp_Association;

    INSERT IGNORE INTO Temp_CustAssociation(CustID_1, CustID_2)
    SELECT DISTINCT CustID_1, CustID_1
    FROM Temp_Association;

    INSERT INTO Temp_CustAssociation01(CustID_1,MinTransDate_1,MaxTransDate_1,CustID_2,MinTransDate_2,MaxTransDate_2)
    SELECT 	tmpC1.CustID
		,	tmpC1.MinTransDate
        ,	tmpC1.MaxTransDate
        ,	tmpC2.CustID
		,	tmpC2.MinTransDate
        ,	tmpC2.MaxTransDate
    FROM Temp_CustAssociation AS tmpAss
		INNER JOIN Temp_CustTime01 AS tmpC1 ON tmpC1.CustID = tmpAss.CustID_1
        INNER JOIN Temp_CustTime02 AS tmpC2 ON tmpC2.CustID = tmpAss.CustID_2;
	
	lp: LOOP        
        SET lv_CustID = 0;
        
		SELECT  CustID_1, MinTransDate_1, MaxTransDate_1
		INTO lv_CustID, lv_MinTransDate, lv_MaxTransDate
		FROM Temp_CustAssociation01
		ORDER BY CustID_1, MinTransDate_1
		LIMIT 1;		
  
		IF lv_CustID =0 
        THEN			
            LEAVE lp; 
        END IF;
	
        INSERT INTO Temp_TransGroup(CustID, MinTransDate, MaxTransDate, GroupID)
		WITH RECURSIVE CTE_Group AS ( 
			SELECT lv_CustID AS CustID, lv_MinTransDate AS MinTransDate, lv_MaxTransDate AS MaxTransDate  
			UNION
			SELECT tmpCa.CustID_2, tmpCa.MinTransDate_2, tmpCa.MaxTransDate_2
            FROM Temp_CustAssociation01  AS tmpCa
				JOIN CTE_Group ON CTE_Group.CustID = tmpCa.CustID_1 
                AND (
						ABS(TIMESTAMPDIFF(SECOND,tmpCa.MinTransDate_2,MaxTransDate))  <= lv_Rule_TimeStep 
					OR	ABS(TIMESTAMPDIFF(SECOND,tmpCa.MaxTransDate_2,MinTransDate))  <= lv_Rule_TimeStep 
                    OR	ABS(TIMESTAMPDIFF(SECOND,tmpCa.MinTransDate_2,MinTransDate))  <= lv_Rule_TimeStep
                    OR 	ABS(TIMESTAMPDIFF(SECOND,tmpCa.MaxTransDate_2,MaxTransDate))  <= lv_Rule_TimeStep  
                )
		) 
		SELECT	CustID, MinTransDate, MaxTransDate, lv_GroupID 
		FROM CTE_Group;
		
        DELETE tmpCa
        FROM Temp_CustAssociation01 AS tmpCa
			INNER JOIN Temp_TransGroup AS tmpTg ON tmpCa.CustID_1 = tmpTg.CustID AND tmpCa.MinTransDate_1 = tmpTg.MinTransDate AND tmpCa.MaxTransDate_1 = tmpTg.MaxTransDate;
        
		SET lv_GroupID = lv_GroupID + 1;
        
		SET @i = @i+1;
        
	END LOOP;     
	
    INSERT INTO Temp_TransGroup02 SELECT * From Temp_TransGroup;
    
    #*************************************************************************************************
	INSERT INTO Temp_ResultGroup(GroupID, Reason, TransIDList, CustIDList, OldGroupIDList, HighStakeLicCustList , LicenseeCustTotal)
    SELECT  tmpTg.GroupID
        ,	lv_Rule_Reason AS Reason
        ,	GROUP_CONCAT(tmpSt.TransID) AS TransIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.CustID) AS CustIDList
        ,	GROUP_CONCAT(DISTINCT CASE WHEN tmpSt.OldGroupID > 0 THEN tmpSt.OldGroupID ELSE 0 END) AS OldGroupIDList 
        ,	GROUP_CONCAT(DISTINCT (CASE WHEN tmpSt.Stake >= lv_ClassifyHighStake AND cus.IsLicensee = 1 THEN tmpTg.CustID ELSE NULL END)) AS HighStakeLicCustList
        ,	COUNT(DISTINCT (CASE WHEN cus.IsLicensee = 1 THEN cus.CustID ELSE NULL END)) AS LicenseeCustTotal
    FROM 	Temp_TransGroup AS tmpTg
		INNER JOIN Temp_StagingTrans02  AS tmpSt ON tmpSt.CustID = tmpTg.CustID AND tmpSt.TransDate BETWEEN tmpTg.MinTransDate AND tmpTg.MaxTransDate
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpTg.CustID 
	GROUP BY tmpTg.GroupID
    HAVING SUM(Stake) >= lv_Rule_TotalStake AND COUNT(DISTINCT tmpSt.CustID) > 1;

    UPDATE Temp_StagingTrans02 AS mms
		INNER JOIN Temp_TransGroup02 AS tmpSt ON  mms.CustID = tmpSt.CustID AND mms.TransDate BETWEEN tmpSt.MinTransDate AND tmpSt.MaxTransDate
		LEFT JOIN Temp_ResultGroup AS tmpRg ON tmpSt.GroupID = tmpRg.GroupID
	SET mms.OldGroupID = -tmpSt.GroupID
	WHERE tmpRg.GroupID IS NULL;
	
	IF (ip_LiveIndicator = 1) THEN 
		UPDATE CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
			INNER JOIN Temp_StagingTrans02 AS tmpSt ON mms.SequenceID = tmpSt.SequenceID
		SET mms.GroupID = tmpSt.OldGroupID
		WHERE tmpSt.OldGroupID < 0 and mms.GroupID <= 0;
	ELSE
		UPDATE CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms
			INNER JOIN Temp_StagingTrans02 AS tmpSt ON mms.SequenceID = tmpSt.SequenceID
		SET mms.GroupID = tmpSt.OldGroupID
		WHERE tmpSt.OldGroupID < 0 and mms.GroupID <= 0;
	END IF;
    
	SELECT	tmpRg.GroupID
		,	tmpRg.Reason
        ,	tmpRg.TransIDList
        ,	tmpRg.CustIDList
        ,	tmpRg.OldGroupIDList
        ,	(CASE WHEN tmpRg.LicenseeCustTotal >= 3 AND tmpRg.HighStakeLicCustList IS NOT NULL THEN HighStakeLicCustList ELSE NULL END) HighStakeLicCustList
    FROM Temp_ResultGroup AS tmpRg;
    
END$$
DELIMITER ;
