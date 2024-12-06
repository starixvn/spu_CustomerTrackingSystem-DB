/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241206@Casey.Huynh	
Task:	 	Hotfix Protential Risk Cannot be Classified to System Detect GB - CORRECT Data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241206@Casey.Huynh: Created [Redmine ID: #214567]
Reviewer:
*/

	/*********************SCHEMA*****************************/
    USE CTS_Adhoc;
    CREATE TABLE HF214567_MatchMonitorDetailsCust_ALL(
			CustID			INT UNSIGNED
		,	MMDetailsID		INT
        ,	Reason			TINYINT
		,	MatchID			INT		      
        ,	NoOfCust		INT
        ,	EventDate		DATETIME
        
        ,	INDEX IX_Temp_MatchMonitorDetailsCust(CustID, MMDetailsID)
    );
    
	CREATE TABLE HF214567_MatchMonitorDetailsCust_DISTINCT(
			CustID			INT UNSIGNED
		,	MMDetailsID		INT
        ,	Reason			TINYINT
		,	MatchID			INT		      
        ,	NoOfCust		INT
        ,	EventDate		DATETIME
        
        ,	PRIMARY KEY IX_Temp_MatchMonitorDetailsCust(CustID)
    );
        
    CREATE TABLE HF214567_MatchMonitorDetailsCust_CorrectData(
			CustID			INT UNSIGNED
		,	UserName		VARCHAR(50)
		,	MMDetailsID		INT  
		,	MatchID			INT		      
        ,	CTSCustID		BIGINT UNSIGNED
        ,	RoleID			TINYINT
        ,	SubscriberID	INT UNSIGNED
        ,	IsLicensee		TINYINT(1)
        ,	EventDate		DATETIME
        ,	CurrentCategory	VARCHAR(500)
        
        ,	PRIMARY KEY IX_Temp_MatchMonitorDetailsCust(CustID)
    );
    
    #DELETE del FROM CTS_Adhoc.HF214567_MatchMonitorDetailsCust_ALL del;
    #DELETE del FROM CTS_Adhoc.HF214567_MatchMonitorDetailsCust_DISTINCT del;
    #DELETE del FROM CTS_Adhoc.HF214567_MatchMonitorDetailsCust_CorrectData del;
    
	#===================================GET DATA========================================    
    USE CTS_DataCenter;
    
    SET @CONST_CATEID_SYSTEMDETECTGB	 		= 20900;#SELECT CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SYSTEMDETECTGB');    
    SET @CONST_CATEGROUPID_SYSTEMDETECTGB 		= 20900;#SELECT CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SYSTEMDETECTGB');
    
    /*****GET SYSTEM Parameter VALUE****/
	
	USE CTS_DataCenter;
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID			INT UNSIGNED
		,	MMDetailsID		INT  
		,	MatchID			INT		      
        ,	CTSCustID		BIGINT UNSIGNED
        ,	RoleID			TINYINT
        ,	SubscriberID	INT UNSIGNED
        ,	IsLicensee		TINYINT(1)
        ,	EventDate		DATETIME
        
        ,	PRIMARY KEY PK_Temp_Cust(CustID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExcludePACategoryID;
    CREATE TEMPORARY TABLE Temp_ExcludePACategoryID(
    
			CategoryID		INT UNSIGNED	       
        ,	PRIMARY KEY PK_Temp_ExcludePA(CategoryID)
    );

	INSERT INTO Temp_ExcludePACategoryID(CategoryID)
    SELECT ccs.CategoryID
    FROM CTS_DataCenter.CustomerCategorySettings AS ccs
    WHERE	ParentID = 20000 
		AND CategoryID NOT IN (
			21600,21700,21100,26100,21200,26200,21103 #@CONST_CATEID_ROBOTBETTING, @CONST_CATEID_ROBOTOLD, @CONST_CATEID_ROBOTUSER, @CONST_CATEID_ROBOTUSERLOSING, @CONST_CATEID_ROBOTOCRD, @CONST_CATEID_ROBOTOCRDLOSING, @CONST_CATEID_ROBOTUSERABNORMAL
		,	30100,30200,30300,35100,35200,35300	 #PROTENTIAL RISK CATEGORY
			);
	
    INSERT INTO CTS_Adhoc.HF214567_MatchMonitorDetailsCust_ALL(CustID, MMDetailsID, MatchID, NoOfCust, EventDate)
    WITH CTE_MatchMonitorDetials AS
    ( 	SELECT	mmd.ID AS MMDetailsID
			,	mmd.HighStakeLicCustList
            ,	mmd.MatchID
            ,	mm.EventDate
		FROM CTS_DataCenter.MatchMonitorDetails AS mmd
			INNER JOIN CTS_DataCenter.MatchMonitor AS mm ON mmd.MatchID = mm.MatchID
        WHERE mmd.Reason = 0            
			AND mmd.HighStakeLicCustList IS NOT NULL
			AND mm.EventDate >= '2024-10-14' AND mm.EventDate < '2024-12-06'
					AND mm.SportType IN (1,2) 
					AND mm.LeagueGroupID IS NULL
					AND mm.ClassifyStatus = 1
	)
	SELECT	js.CustID
		,	cte.MMDetailsID
        ,	cte.MatchID
        ,	LENGTH(cte.HighStakeLicCustList) - LENGTH(REPLACE(cte.HighStakeLicCustList,',','')) + 1 AS NoOfCust	
        ,	cte.EventDate
	FROM CTE_MatchMonitorDetials AS cte
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(cte.HighStakeLicCustList), ',', '","'), 
						'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
						) js;    
	
    
    INSERT IGNORE INTO CTS_Adhoc.HF214567_MatchMonitorDetailsCust_DISTINCT
    SELECT *
    FROM CTS_Adhoc.HF214567_MatchMonitorDetailsCust_ALL
    ORDER BY EventDate ASC, MMDetailsID ASC;
    
    INSERT INTO Temp_Cust(CustID, MMDetailsID, MatchID, CTSCustID, RoleID, SubscriberID, IsLicensee, EventDate)
    SELECT	tmpMmc.CustID
		,	tmpMmc.MMDetailsID
        ,	tmpMmc.MatchID
        ,	cus.CTSCustID
        ,	cus.RoleID
        ,	cus.SubscriberID
        ,	cus.IsLicensee
        ,	tmpMmc.EventDate
    FROM CTS_Adhoc.HF214567_MatchMonitorDetailsCust_DISTINCT AS tmpMmc
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpMmc.CustID = cus.CustID
	WHERE tmpMmc.CustID IS NOT NULL;

    INSERT INTO CTS_Adhoc.HF214567_MatchMonitorDetailsCust_CorrectData(CustID,UserName,MatchID,CTSCustID,RoleID,SubscriberID,IsLicensee,EventDate,MMDetailsID,CurrentCategory)
    SELECT	tmpCust.CustID
		,	cus.UserName
        ,	tmpCust.MatchID
        ,	tmpCust.CTSCustID
        ,	tmpCust.RoleID
        ,	tmpCust.SubscriberID
        ,	tmpCust.IsLicensee
        ,	tmpCust.EventDate
        ,	tmpCust.MMDetailsID
        , 	GROUP_CONCAT(CONCAT('{',cat.CategoryName,',',cls.CreatedDate,'}')) AS CurrentCategory
       # ,	SUM(CASE WHEN cls.CategoryID  IN (30100,30200,30300,35100,35200,35300) THEN 1 ELSE 0 END) CountPotential
       # ,	MAX(CASE WHEN exl.CategoryID IS NOT NULL THEN 1 ELSE 0 END) AS IsExcludedPA
       # ,	@CONST_CATEID_SYSTEMDETECTGB AS CategoryID # Group Betting
       # , 	@CONST_CATEGROUPID_SYSTEMDETECTGB AS CategoryGroup # Group Betting
	FROM Temp_Cust AS tmpCust
		INNER JOIN CTSCustomer AS cus ON tmpCust.CustID = cus.CustID
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON tmpCust.CustID = cls.CustID
        LEFT JOIN Temp_ExcludePACategoryID AS exl ON cls.CategoryID = exl.CategoryID
        LEFT JOIN CustomerCategory AS cat ON cat.CategoryID = cls.CategoryID
    GROUP BY tmpCust.CustID
		,	cus.UserName
        ,	tmpCust.MatchID
        ,	tmpCust.CTSCustID
        ,	tmpCust.RoleID
        ,	tmpCust.SubscriberID
        ,	tmpCust.IsLicensee
        ,	tmpCust.EventDate
        ,	tmpCust.MMDetailsID
	HAVING SUM(CASE WHEN cls.CategoryID  IN (30100,30200,30300,35100,35200,35300) THEN 1 ELSE 0 END) > 0 #COUNT POTENTIAL
		AND MAX(CASE WHEN exl.CategoryID IS NOT NULL THEN 1 ELSE 0 END) = 0 # #NOT EXCLUDE PA
	; #189 row(s) affected Records: 189  Duplicates: 0  Warnings: 0

        

