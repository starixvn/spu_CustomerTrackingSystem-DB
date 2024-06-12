/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleGroupBetting_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleGroupBetting_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_ScoreDiff			INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_Betteam			VARCHAR(10)
    ,	IN ip_SportType			INT
    ,	IN ip_SequenceIDList	TEXT		# SequenceID List from SP CTS_DC_MatchMonitor_RuleGroupBetting_Get
    ,	IN ip_CustGroup			JSON 		# Group Return from DC_Association_DetectGroup    
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
			- 	20220422@Irena.Vo: 		Mapping Is Hedging Reason (MM) from table CustomerCategory [Redmine ID: #170468]
			-	20220815@Casey.Huynh: 	Scale Out DB [Redmine ID: #176472]
			- 	20220830@Casey.Huynh: 	New Category for Classify Group Betting [Redmine ID: #176976]
			-	202200929@Casey.Huynh: 	Seperate By Sport [Redmine ID: #178310]
			-	20221021@Casey.Huynh: 	Fixed Clean Data Staging [Redmine ID: #179427]
			-	20221027@Casey.Huynh: 	Seperate pool Staging [RedmineID: 179439]
			-	20221205@Casey.Huynh: 	Rename Table and remove (Arbitrage,Hedging) [Redmine ID: #179502]
			-	20230221@Casey.Huynh: 	Update Rule, The same Choice [Redmine ID: #184041]
			- 	20230112@Victoria.Le: 	Modify SPs due to restructure AssociationByAI [Redmine ID: #181994]
            -	20230313@Casey.Huynh:	Applied Betting Parten OTGB [Redmine ID: #184791]
			-	20230421@Casey.Huynh:	Enhance Rule for System Detect Classification [Redmine ID: #186814]
            -	20231016@Casey.Huynh:	Enhance Rule for BasketBall. Adjust Group Stake to 300, Add AssociationByIP, ShareMatch(3 Match(last 7 day) [Redmine ID: 195473]
            -	20231120@Thomas.Nguyen: Add the condition stake of licensee group for Basketball: >= 50RM [Redmine ID: #188553]
            -	20231120@Casey.Huynh:	Enhance Rule for Esport. Adjust Group Stake to 300, Add AssociationByIP, ShareMatch(3 Match(last 7 day) [Redmine ID: #196396]
            -	20240627@Casey.Huynh:	EuroCup Exclude AssociationByIP [RedmineID: #207117]
            -	20240716@Casey.Huynh:	After EuroCup, Rollback AssociationByIP [RedmineID: #207117]
            
		Param's Explanation (filtered by):	
		Example:
			Example:
			CALL CTS_DC_MatchMonitor_RuleGroupBetting_Process(
             @ip_LiveIndicator:=1
            ,@ip_MatchID:=22081995
            ,@ip_ScoreDiff:=1
            ,@ip_BettypeID:=1
            ,@ip_BetID:=0
            ,@ip_Betteam:='a'
            ,@ip_SequenceIDList:=''
            ,@ip_CustGroup:='[{"CustID":,"GroupID":},{"CustID":,"GroupID":}]');
						
	*/
	
	DECLARE CONST_LOG 						TINYINT DEFAULT 0;
    DECLARE CONST_MMRULEGROUP_GROUPBETTING	INT DEFAULT 1;
    DECLARE CONST_MMREASON_GROUPBETTING		INT DEFAULT 0;
	DECLARE CONST_CLASSIFYTOTALSTAKE_SOCCER	DECIMAL(20,4) DEFAULT 80;
	DECLARE CONST_CLASSIFYTOTALCUST			INT DEFAULT 3;

	DECLARE lv_RuleTimeStep 				SMALLINT;
	DECLARE lv_RuleTotalStake 				DECIMAL(20,4);
	DECLARE lv_CustIDList 					LONGTEXT;
	DECLARE lv_GroupID 						INT; 

    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleGroupBetting_Process';
    IF CONST_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator,',@ip_MatchID:=',ip_MatchID
		,',@ip_ScoreDiff:=',ip_ScoreDiff,',@ip_BettypeID:=',ip_BettypeID,',@ip_BetID:=',ip_Betteam,',@ip_HDP:=',ip_Betteam);
    END IF;
    
    #==================LOG=======================================================   
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			GroupID			INT
		,	OrderNum		INT
        ,	SequenceID		BIGINT
        ,	TransDateToSecond BIGINT
        ,	TransID			BIGINT
        ,	CustID			BIGINT
        ,	CTSCustID		BIGINT
        ,	Stake			DECIMAL(20,4)
        ,	OldGroupID		INT
        ,	TimeGroupID		INT
		,	IsLicensee		BOOLEAN
        
        ,	PRIMARY KEY PK_Temp_Trans_GroupID_OrderNum(GroupID, OrderNum)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans2;
    CREATE TEMPORARY TABLE Temp_Trans2(
			GroupID			INT
		,	OrderNum		INT
        ,	SequenceID		BIGINT
        ,	TransDateToSecond BIGINT
        ,	TransID			BIGINT
        ,	CustID			BIGINT
        ,	CTSCustID		BIGINT
        ,	Stake			DECIMAL(20,4)
        ,	OldGroupID		INT
        
        ,	PRIMARY KEY PK_Temp_Trans_GroupID_OrderNum(GroupID, OrderNum)
    );
       
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE Temp_Cust (
		 	CustID 	BIGINT UNSIGNED PRIMARY KEY
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE Temp_Group(
			GroupID 			INT
		,	TimeGroupID			BIGINT PRIMARY KEY
		,	TransIDList			LONGTEXT
        ,	OldGroupIDList		VARCHAR(500)
		,	CustIDList			LONGTEXT
		,	CTSCustIDList		LONGTEXT
		,	SequenceIDList		LONGTEXT
        ,	IsValidGroup		BOOLEAN
        ,	LicCustTotalStake	INT
        ,	LicCustTotal		INT
	);
    #=======================================================================
	SELECT 	st.TotalStake, st.TimeStep
	INTO 	lv_RuleTotalStake, lv_RuleTimeStep
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS st 
	WHERE 	st.RuleGroupID = CONST_MMRULEGROUP_GROUPBETTING AND st.RuleStatus = 1
	LIMIT 1;

    DROP TEMPORARY TABLE IF EXISTS Temp_CustGroup;
    CREATE TEMPORARY TABLE Temp_CustGroup(
			CustID		BIGINT
        ,	GroupID		INT
	);
    
    INSERT INTO Temp_CustGroup(CustID, GroupID)
    SELECT  js.CustID
		,	js.GroupID
	FROM JSON_TABLE(ip_CustGroup,
					 "$[*]" COLUMNS(
								CustID		BIGINT UNSIGNED PATH "$.CustID" 	
							,	GroupID		INT PATH "$.GroupID"
						)
					) AS js;  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_SequenceID;
    CREATE TEMPORARY TABLE Temp_SequenceID (
			SequenceID	BIGINT UNSIGNED PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_SequenceID (SequenceID) VALUES ('", REPLACE(ip_SequenceIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    IF (ip_LiveIndicator = 1) THEN
    
		INSERT INTO Temp_Trans(GroupID, OrderNum ,SequenceID,TransDateToSecond,TransID,CustID,CTSCustID, Stake, OldGroupID)
        SELECT	tmpCg.GroupID
			,	ROW_NUMBER() OVER (PARTITION BY tmpCg.GroupID ORDER BY SequenceID ) AS OrderNum			
			,	mms.SequenceID
			,	mms.TransDateToSecond
			,	mms.TransID
			,	mms.CustID
			,	mms.CTSCustID
			,	mms.Stake
            ,	mms.GroupID
            ,	mms.IsLicensee
        FROM	CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
			INNER JOIN Temp_SequenceID AS tmpSq ON tmpSq.SequenceID = mms.SequenceID
			INNER JOIN Temp_CustGroup AS tmpCg ON tmpCg.CustID = mms.CustID;
            
		INSERT INTO Temp_Trans2(GroupID, OrderNum, SequenceID,TransDateToSecond,TransID,CustID,CTSCustID,Stake,OldGroupID)
		SELECT tmpTs.GroupID
			,	tmpTs.OrderNum
            ,	tmpTs.SequenceID
            ,	tmpTs.TransDateToSecond
            ,	tmpTs.TransID
            ,	tmpTs.CustID
            ,	tmpTs.CTSCustID
            ,	tmpTs.Stake
            ,	tmpTs.OldGroupID
		FROM Temp_Trans AS tmpTs;

        SET @n=0;
        UPDATE Temp_Trans AS t
			LEFT JOIN Temp_Trans2 AS t2 ON t.GroupID = t2.GroupID AND t.OrderNum = t2.OrderNum  +1 AND t.TransDateToSecond - t2.TransDateToSecond <= 180
		SET t.TimeGroupID = (CASE WHEN t2.OrderNum IS NOT NULL THEN @n ELSE @n:=@n+1  END);
		
        INSERT INTO Temp_Group(GroupID, TimeGroupID, TransIDList, OldGroupIDList, CustIDList, CTSCustIDList, SequenceIDList, LicCustTotalStake, LicCustTotal, IsValidGroup)        
        SELECT	MIN(tmp.GroupID) AS GroupID
			,	tmp.TimeGroupID
            ,	GROUP_CONCAT(tmp.TransID ORDER BY tmp.TransID) AS TransIDList
			,	GROUP_CONCAT(DISTINCT tmp.OldGroupID) AS OldGroupIDList
            ,	GROUP_CONCAT(DISTINCT tmp.CustID) AS CustIDList
            ,	GROUP_CONCAT(DISTINCT tmp.CTSCustID) AS CTSCustIDList
			,	GROUP_CONCAT(tmp.SequenceID)
            ,	SUM((CASE WHEN tmp.IsLicensee = 1 THEN tmpSt.Stake ELSE 0 END)) AS LicCustTotalStake
			,	COUNT(DISTINCT (CASE WHEN tmp.IsLicensee = 1 THEN cus.CustID ELSE NULL END)) AS LicCustTotal
            ,	(CASE WHEN COUNT(DISTINCT CustID) > 1 AND SUM(Stake) >= lv_RuleTotalStake THEN 1 ELSE 0 END) AS IsValidGroup
        FROM Temp_Trans AS tmp
        GROUP BY TimeGroupID;

	ELSE #(ip_LiveIndicator = 0)
		
		INSERT INTO Temp_Trans(GroupID, OrderNum ,SequenceID,TransDateToSecond,TransID,CustID,CTSCustID, Stake, OldGroupID)
        SELECT	tmpCg.GroupID
			,	ROW_NUMBER() OVER (PARTITION BY tmpCg.GroupID ORDER BY SequenceID ) AS OrderNum			
			,	mms.SequenceID
			,	mms.TransDateToSecond
			,	mms.TransID
			,	mms.CustID
			,	mms.CTSCustID
			,	mms.Stake
            ,	mms.GroupID
        FROM	CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms
			INNER JOIN Temp_SequenceID AS tmpSq ON tmpSq.SequenceID = mms.SequenceID
			INNER JOIN Temp_CustGroup AS tmpCg ON tmpCg.CustID = mms.CustID;
            
		INSERT INTO Temp_Trans2(GroupID, OrderNum, SequenceID, TransDateToSecond, TransID, CustID, CTSCustID, Stake, OldGroupID)
		SELECT tmpTs.GroupID
			,	tmpTs.OrderNum
            ,	tmpTs.SequenceID
            ,	tmpTs.TransDateToSecond
            ,	tmpTs.TransID
            ,	tmpTs.CustID
            ,	tmpTs.CTSCustID
            ,	tmpTs.Stake
            ,	tmpTs.OldGroupID
		FROM Temp_Trans AS tmpTs;

        SET @n=0;
        
        UPDATE Temp_Trans AS t
			LEFT JOIN Temp_Trans2 AS t2 ON t.GroupID = t2.GroupID AND t.OrderNum = t2.OrderNum + 1 AND t.TransDateToSecond - t2.TransDateToSecond <= 180
		SET t.TimeGroupID = (CASE WHEN t2.OrderNum IS NOT NULL THEN @n ELSE @n:=@n+1  END);
		
        INSERT INTO Temp_Group(GroupID, TimeGroupID, TransIDList, OldGroupIDList, CustIDList, CTSCustIDList, SequenceIDList, LicCustTotalStake, LicCustTotal, IsValidGroup)        
        SELECT	MIN(tmp.GroupID) AS GroupID
			,	tmp.TimeGroupID
            ,	GROUP_CONCAT(tmp.TransID ORDER BY tmp.TransID) AS TransIDList
			,	GROUP_CONCAT(DISTINCT tmp.OldGroupID) AS OldGroupIDList
            ,	GROUP_CONCAT(DISTINCT tmp.CustID) AS CustIDList
            ,	GROUP_CONCAT(DISTINCT tmp.CTSCustID) AS CTSCustIDList
			,	GROUP_CONCAT(tmp.SequenceID)
			,	SUM((CASE WHEN tmp.IsLicensee = 1 THEN tmpSt.Stake ELSE 0 END)) AS LicCustTotalStake
			,	COUNT(DISTINCT (CASE WHEN tmp.IsLicensee = 1 THEN cus.CustID ELSE NULL END)) AS LicCustTotal
            ,	(CASE WHEN COUNT(DISTINCT CustID) > 1 AND SUM(Stake) >= lv_RuleTotalStake THEN 1 ELSE 0 END) AS IsValidGroup
        FROM Temp_Trans AS tmp
        GROUP BY TimeGroupID;
    END IF;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Completed;
	CREATE TEMPORARY TABLE Temp_Completed(GroupID INT PRIMARY KEY);
	
	INSERT INTO Temp_Completed(GroupID)
	SELECT tmpGp.GroupID
	FROM Temp_Group AS tmpGp
	GROUP BY tmpGp.GroupID
	HAVING COUNT(DISTINCT tmpGp.TimeGroupID) = 1 AND MAX(IsValidGroup) = 1;

	SELECT	tmpGr.GroupID	
        ,	tmpGr.CustIDList
        ,	tmpGr.TransIDList
        ,	(CASE WHEN ((lv_SportType = CONST_SPORTTYPE_SOCCER AND tmpRg.LicCustTotalStake >= CONST_CLASSIFYTOTALSTAKE_SOCCER) OR (lv_SportType = CONST_SPORTTYPE_BASKETBALL AND tmpRg.LicCustTotalStake >= CONST_CLASSIFYTOTALSTAKE_BASKETBALL)) AND LicCustTotal >= CONST_CLASSIFYTOTALCUST THEN LicCustList ELSE NULL END) HighStakeLicCustList
    FROM Temp_Group AS tmpGr
		INNER JOIN Temp_Completed AS tmpCp ON tmpGr.GroupID = tmpCp.GroupID
    WHERE tmpCp.GroupID IS NOT NULL AND tmpGr.IsValidGroup = 1;

    SELECT	tmpGr.CTSCustIDList
        ,	tmpGr.SequenceIDList
    FROM Temp_Group AS tmpGr
		LEFT JOIN Temp_Completed AS tmpCp ON tmpGr.GroupID = tmpCp.GroupID
	WHERE tmpCp.GroupID IS NULL AND tmpGr.IsValidGroup = 1;
    
END$$
DELIMITER ;
