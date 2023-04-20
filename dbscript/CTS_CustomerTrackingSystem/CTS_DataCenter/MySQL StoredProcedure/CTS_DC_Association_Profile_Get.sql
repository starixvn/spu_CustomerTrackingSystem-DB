/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_Association_Profile_Get`;

DELIMITER $$ 
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Profile_Get`(
		IN ip_CTSCustID 		BIGINT UNSIGNED
	,	IN ip_AssociationType	INT
	,	IN ip_AssociationStatus INT 
    ,	IN ip_AccountStatusIDs	VARCHAR(100)
     ,	IN ip_CategoryIDs		TEXT
	, 	IN ip_SubscriberIDs		TEXT
    ,	IN ip_Skip 				INT
    ,	IN ip_Take 				INT
    
    ,	OUT op_TotalItems		INT
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210202@Aries.Nguyen
		Task:		Get association account 
		DB:			CTS_DataCenter
		Revisions:
			- 20210202@Aries.Nguyen: 	Created [Redmine ID: #148908]
			- 20210221@Aries.Nguyen: 	Fix get wrong first association date by device [Redmine ID: #150223]
			- 20210316@Casey.Huynh: 	Get Customer Category Info [Redmine ID: #150457]
			- 20210317@Casey.Huynh: 	Count AssociationByIP to lv_TotalAccounts [Redmine ID: #131662]
			- 20210330@Jonas.Huynh: 	Replace Site filter by Subscriber [Redmine ID: #152252]
			- 20210415@Aries.Nguyen: 	Fix show duplicated records at Associated Accounts [Redmine ID: #153511]
			- 20210419@Irena.Vo: 		Ignore get CC on Associated Accounts tab [Redmine ID: #152250]
			- 20210420@Irena.Vo: 		Get data for Sub Account on Associated Accounts tab [Redmine ID: #152963]
			- 20210505@Irena.Vo: 		Get additional CustId [Redmine ID: #152963]
			- 20210506@Irena.Vo: 		Get additional CustSubId [Redmine ID: #154624]            
			- 20220328@Aries.Nguyen: 	Add new category/class for PA Probation [Redmine ID: #170468]
			- 20220408@Long.Luu: 		Get more data from AssociationGroupByAI [Redmine ID: #171222]
			- 20220705@Aries.Nguyen: 	Tuning SP [Redmine ID: #174430]
			- 20230112@Victoria.Le: 	Modify SPs due to restructure AssociationByAI [Redmine ID: #181994]
            - 20230313@Casey.Huynh:		Applied Betting Parten OTGB [Redmine ID: #184791]
            - 20230421@Casey.Huynh: 	Handle Fist Association Date [Redmine ID: #185783]
		Param's Explanation (filtered by):
			- ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
            - ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked
            - ip_AccountStatusIDs: 0,1,11,2,3,4,12,13,14 - All,    1,11 - Open(1:Open, 11:Active),  2,3,4,12,13,14 - Closed (2:Disabled, 3:Closed, 4:Suspended, 12:Inactive, 13:View Only, 14:Suspended), 0: Other (sub account)
            - ip_CategoryIDs: 0, 51,205,206,...-Selected CategoryIDs (0-'No Category' Option)
            
        Example:
			  CALL CTS_DataCenter.CTS_DC_Association_Profile_Get (@ip_CTSCustID:= 5422,@ip_AssociationType:= 0,@ip_AssociationStatus:= 0,@ip_AccountStatusIDs:= '0,1,11,2,3,4,12,13,14'
              ,@ip_CategoryIDs:= '156,56,76,51,151,54,154,74,60,80,55,155,75,52,152,72,73,153,53,78,58,158,160,57,157,61,79,59,159,271,272,273,231,232,233,221,222,223,251,252,253,261,262,263,211,212,213,204,201,202,206,203,205,210,0'
              ,@ip_SubscriberIDs:= '2,130,168,169,4490,4491,4586,4599,13658,13659,898216,898217,898221,898222,898224,898225,898226,898227,898228,898229,898233,898241,898244,898245,898246,898247,898250,898251,898252,898253,898254,898255,898256,898265,898270,898274,898276,898277,898279,898280,898294,898295,4,5,6,7,99,101,102,103,104,105,107,108,111,112,116,120,121,122,125,126,127,128,129,131,138,142,144,146,147,149,150,151,152,156,157,158,160,161,162,165,166,172,173,175,176,177,179,180,181,184,185,186,187,189,190,191,193,195,196,197,198,199,200,204,207,209,212,213,216,217,221,223,225,226,229,230,231,232,234,235,236,237,241,243,244,245,247,249,251,252,253,255,258,263,266,269,270,271,273,275,1270,1271,1272,1273,1274,1275,1277,1280,1282,1284,1286,1287,1288,1289,1290,1291,1293,1294,1295,1296,1297,1298,1300,1301,1302,1303,1304,1305,1307,1308,1309,1310,1312,1313,1314,1315,1316,1317,2309,2310,2311,2312,2313,2314,2316,2317,2318,2319,2320,2321,2322,2323,2324,2325,2327,2328,2329,2330,2331,2332,2333,2334,2335,2337,2340,2342,2343,2344,2345,2346,2347,2348,2349,2350,2351,2352,2353,2355,2356,2357,2358,2359,2360,2362,2363,2364,2365,2367,2368,2369,2370,2371,2372,2373,2374,2375,2376,3373,3374,3375,3376,3377,3379,3380,3381,3382,3383,3384,3385,3386,3387,3388,3389,3390,3391,3392,3393,3394,4388,4389,4390,4391,4392,4393,4394,4395,4396,4397,4398,4399,4400,4401,4402,4403,4404,4405,4406,4408,4409,4410,4411,4412,4413,4414,4415,4416,4417,4418,4419,4420,4421,4422,4423,4424,4425,4426,4429,4430,4432,4433,4434,4435,4436,4437,4438,4439,4440,4441,4442,4444,4445,4446,4447,4448,4449,4450,4451,4452,4453,4454,4455,4456,4457,4458,4459,4460,4461,4462,4463,4464,4465,4466,4467,4468,4469,4470,4471,4473,4474,4475,4476,4477,4478,4479,4480,4481,4482,4483,4484,4485,4486,4487,4488,4489,4492,4493,4494,4495,4496,4497,4498,4499,4500,4501,4502,4503,4504,4505,4506,4507,4508,4509,4510,4511,4512,4513,4514,4515,4516,4517,4518,4519,4520,4521,4522,4523,4524,4525,4526,4527,4528,4529,4530,4531,4532,4533,4534,4535,4536,4537,4538,4539,4540,4541,4542,4543,4544,4545,4546,4547,4548,4549,4550,4551,4552,4553,4554,4555,4556,4557,4558,4559,4560,4561,4562,4563,4564,4565,4566,4567,4568,4569,4570,4571,4572,4573,4574,4575,4576,4577,4578,4579,4580,4581,4582,4583,4584,4585,4587,4588,4589,4590,4591,4592,4593,4594,4595,4596,4597,4598,4600,4601,4602,4603,4610,4611,4624,4625,4626,4627,4628,4629,4630,4631,4632,13656,13657,13660,13661,13662,13663,13664,13665,13666,13667,13668,13669,13670,13671,13672,13673,13677,13678,13679,13680,13681,13682,13683,13684,13685,13686,13687,13688,13689,13690,13691,898193,898194,898195,898196,898197,898198,898199,898200,898201,898202,898203,898204,898205,898206,898207,898208,898209,898210,898211,898223,898249,898257,898260,898271,898273,898296,2338,2339'
              ,@ip_Skip:= 0,@ip_Take:= 5000, @op_TotalItems);               
               select @op_TotalItems; 
	*/
	DECLARE CONST_ASSTYPE_BETTINGPATTERN INT DEFAULT 2;
    DECLARE CONS_ASSBYAI_ACTIVESTATUS INT DEFAULT 1;
    #==================================================
	DECLARE lv_CustID INT;
    
    #=====================DEBUG LOG===========================================
	DECLARE lv_IsLog BOOLEAN DEFAULT 0;    
	DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_Association_Profile_Get';
	IF lv_IsLog = 1 THEN
		SET @LogInfo = CONCAT('@ip_CTSCustID:=''',IFNULL(ip_CTSCustID,'NULL'),''''
								,',@ip_AssociationType:=''',IFNULL(ip_AssociationType,'NULL'),''''
                                ,',@ip_AssociationStatus:=''',IFNULL(ip_AssociationStatus,'NULL'),''''
                                ,',@ip_AccountStatusIDs:=''',IFNULL(ip_AccountStatusIDs,'NULL'),''''
                                ,',@ip_CategoryIDs:=''',IFNULL(ip_CategoryIDs,'NULL'),''''
                                ,',@ip_SubscriberIDs:=''',IFNULL(ip_SubscriberIDs,'NULL'),''''
                                ,',@ip_Skip:=''',IFNULL(ip_Skip,'NULL'),''''
                                ,',@ip_Take:=''',IFNULL(ip_Take,'NULL'),'''');
        
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), @LogInfo; 
	END IF;  
	#========================================================================
    IF (ip_SubscriberIDs IS NULL OR ip_SubscriberIDs = '' OR ip_SubscriberIDs = -1) OR  (ip_CategoryIDs IS NULL OR ip_CategoryIDs = '' OR ip_CategoryIDs = -1) THEN
		LEAVE sp;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedAccount;
    CREATE TEMPORARY TABLE 		Temp_AssociatedAccount (
			CTSCustID			BIGINT UNSIGNED
		,	CustID				BIGINT UNSIGNED
        ,	CustSubID			INT UNSIGNED
		,	SiteID				INT UNSIGNED
        ,	SiteName			VARCHAR(50)
        ,	SubscriberID 		INT UNSIGNED
        ,	SubscriberName		VARCHAR(50)
        ,	UserName			VARCHAR(50)
        ,	UserName2			VARCHAR(50)
		,	AccountStatusGroup	INT
        ,	AccountStatusID		INT
		,	AccountStatusName	VARCHAR(20)
        ,	AssociationType 	INT
        ,	AssociationTypeName	VARCHAR(50)
		, 	AssociationStatus	INT
        ,	AssociationDate		DATETIME
        ,	IsFiltered	        BIT DEFAULT 0
        , 	PRIMARY KEY(CTSCustID)
        ,	INDEX IX_Temp_AssociatedAccount_CustID(CustID)
        ,	INDEX IX_Temp_AssociatedAccount_SubscriberID(SubscriberID)
	);   
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Classification;
    CREATE TEMPORARY TABLE 	Temp_Classification (
			CTSCustID 		BIGINT UNSIGNED
		,	ParentID		SMALLINT UNSIGNED
		,	CategoryIDs		VARCHAR(1000)
		,	CategoryNames	VARCHAR(5000)
		,	IsProbation		BIT DEFAULT 0
        , 	PRIMARY KEY (CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    CREATE TEMPORARY TABLE 		Temp_Association(
			CTSCustID_Aff 		BIGINT UNSIGNED
        , 	AssociationType		INT
		, 	AssociationStatus	INT
        ,	AssociationDate		DATETIME
        , 	PRIMARY KEY (CTSCustID_Aff,AssociationType,AssociationStatus)
	);  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_UnlinkedAssociation;
    CREATE TEMPORARY TABLE 		Temp_UnlinkedAssociation (
			CTSCustID_Aff 		BIGINT UNSIGNED
        , 	AssociationType		INT
        , 	AssociationStatus	INT
        ,	AssociationDate		DATETIME
        , 	PRIMARY KEY (CTSCustID_Aff,AssociationType,AssociationStatus)
	);  
	
    DROP TEMPORARY TABLE IF EXISTS Temp_SubscriberID;
    CREATE TEMPORARY TABLE 		Temp_SubscriberID (
			SubscriberID 		INT UNSIGNED
        , 	PRIMARY KEY (SubscriberID)
	);   
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountStatusID;
    CREATE TEMPORARY TABLE 		Temp_AccountStatusID (
			AccountStatusID 	INT UNSIGNED
        , 	PRIMARY KEY (AccountStatusID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CategoryID;
    CREATE TEMPORARY TABLE 	Temp_CategoryID (
			CategoryID 		SMALLINT UNSIGNED
        , 	PRIMARY KEY (CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
    CREATE TEMPORARY TABLE 	Temp_Group (
			GroupID 		BIGINT UNSIGNED PRIMARY KEY
		,	OriginGroupID	BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerGroup;
    CREATE TEMPORARY TABLE 	Temp_CustomerGroup (
			CustID 					BIGINT UNSIGNED PRIMARY KEY
		,	AssociationDate			DATETIME
		,	GroupIDList				VARCHAR(1000)        
		,	OriginGroupIDList		VARCHAR(1000)
	);
	#=============================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_AssType;
	CREATE TEMPORARY TABLE 	Temp_AssociationByAI_AssType (
			AssTypeItemValue INT PRIMARY KEY            
	);
    
    #===========GET AssociationByAI status is Applied==============================================    
    INSERT INTO Temp_AssociationByAI_AssType(AssTypeItemValue)
    SELECT atd.AssTypeItemValue
    FROM CTS_DataCenter.AssociationTypeSetting AS atd
    WHERE atd.AssTypeID = CONST_ASSTYPE_BETTINGPATTERN AND atd.AssTypeItemStatus = CONS_ASSBYAI_ACTIVESTATUS;
    
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SubscriberID (SubscriberID) VALUES ('", REPLACE(ip_SubscriberIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 

    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_AccountStatusID (AccountStatusID) VALUES ('", REPLACE(ip_AccountStatusIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;

    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CategoryID (CategoryID) VALUES ('", REPLACE(ip_CategoryIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;

    /* Get CustID */    
    SELECT CustID 
    INTO lv_CustID
    FROM CTS_DataCenter.CTSCustomer 
    WHERE CTSCustID = ip_CTSCustID;
    
    # ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
    IF ip_AssociationType = 0 OR ip_AssociationType = 1 THEN
		INSERT INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus,  AssociationDate)
		SELECT  asCus.CTSCustID  
			,	1 AS AssociationType
            , 	1 AS AssociationStatus
			,	GREATEST(asDv.CreatedTime, asCus.CreatedTime)
		FROM CTS_DataCenter.AssociationByDevice AS asDv 
			INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID = asDv.DCSDeviceID AND asCus.CTSCustID <> ip_CTSCustID
		WHERE asDv.CTSCustID = ip_CTSCustID
        ON DUPLICATE KEY UPDATE AssociationDate = LEAST(Temp_Association.AssociationDate, GREATEST(asDv.CreatedTime, asCus.CreatedTime)); 
    END IF;
    
    # ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
    IF ip_AssociationType = 0 OR ip_AssociationType = 3 THEN
		INSERT IGNORE INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT  asMa.ToCTSCustID 
			,	3 AS AssociationType
            ,   1 AS AssociationStatus
			,	asMa.CreatedDate
		FROM CTS_DataCenter.AssociationByManual AS asMa 
		WHERE	asMa.FromCTSCustID = ip_CTSCustID;
        
        INSERT IGNORE INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT  asMa.FromCTSCustID 
			,	3 AS AssociationType
            ,   1 AS AssociationStatus
			,	asMa.CreatedDate
		FROM CTS_DataCenter.AssociationByManual AS asMa 
		WHERE	asMa.ToCTSCustID =  ip_CTSCustID;
    END IF;

    # ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
    IF ip_AssociationType = 0 OR ip_AssociationType = 2 THEN
		INSERT IGNORE INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT  cust.CTSCustID 
			,	CONST_ASSTYPE_BETTINGPATTERN AS AssociationType
            ,	CONS_ASSBYAI_ACTIVESTATUS AS AssociationStatus
			,	asAI.CreatedDate
		FROM CTS_DataCenter.AssociationByAI AS asAI 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAI.ToCustID AND cust.CustSubID = 0
		WHERE	asAI.FromCustID = lv_CustID
			AND asAI.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByAI_AssType AS tmpAt)
		ORDER BY asAI.CreatedDate ASC;
        
        INSERT IGNORE INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT  cust.CTSCustID 
			,	CONST_ASSTYPE_BETTINGPATTERN AS AssociationType
            ,	CONS_ASSBYAI_ACTIVESTATUS AS AssociationStatus
			,	asAI.CreatedDate
		FROM CTS_DataCenter.AssociationByAI AS asAI 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAI.FromCustID AND cust.CustSubID = 0
		WHERE	asAI.ToCustID = lv_CustID
			AND asAI.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByAI_AssType AS tmpAt)
		ORDER BY asAI.CreatedDate ASC;
        
        INSERT INTO Temp_Group(GroupID, OriginGroupID)
        SELECT DISTINCT GroupID, OriginGroupID
        FROM CTS_DataCenter.AssociationGroupByAI
        WHERE CustID = lv_CustID;
        
        INSERT INTO Temp_CustomerGroup(CustID, AssociationDate, GroupIDList, OriginGroupIDList)
        SELECT  g.CustID
			,	MIN(g.CreatedDate)
            ,	GROUP_CONCAT(g.GroupID SEPARATOR ',')            
            ,	CONCAT(GROUP_CONCAT(g.OriginGroupID SEPARATOR ','), ',', GROUP_CONCAT(t.OriginGroupID SEPARATOR ','))
            #,	GROUP_CONCAT(g.OriginGroupID SEPARATOR ',')
		FROM Temp_Group AS t
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS g ON t.GroupID = g.GroupID AND g.CustID <> lv_CustID
		GROUP BY g.CustID;
        
        INSERT IGNORE INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT   c.CTSCustID
			,	2 AS AssociationType
            ,	1 AS AssociationStatus
			,	t.AssociationDate
		FROM Temp_CustomerGroup AS t
			INNER JOIN CTSCustomer AS c ON t.CustID = c.CustID;
    END IF;
   
	IF ip_AssociationType = 0 OR ip_AssociationType = 4 THEN	
  
		DROP TEMPORARY TABLE IF EXISTS Temp_IPCustID;
        CREATE TEMPORARY TABLE Temp_IPCustID (CustID BIGINT PRIMARY KEY, AssociationDate DATETIME);
        INSERT INTO Temp_IPCustID(CustID, AssociationDate)
        SELECT 	asIP.ToCustID
			,	asIP.CreatedDate
        FROM CTS_DataCenter.AssociationByIP AS asIP 
        WHERE asIP.FromCustID =  lv_CustID
        ON DUPLICATE KEY UPDATE AssociationDate = LEAST(AssociationDate, asIP.CreatedDate);

        INSERT INTO Temp_IPCustID(CustID, AssociationDate)
        SELECT 	asIP.FromCustID
			,	asIP.CreatedDate
        FROM CTS_DataCenter.AssociationByIP AS asIP 
        WHERE asIP.ToCustID =  lv_CustID
        ON DUPLICATE KEY UPDATE AssociationDate = LEAST(AssociationDate, asIP.CreatedDate);        

        INSERT INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT  cus.CTSCustID 
			,	4 AS AssociationType
            ,	1 AS AssociationStatus
			,	tmpIp.AssociationDate
		FROM Temp_IPCustID AS tmpIp
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID  = tmpIp.CustID AND cus.CustSubID = 0;	

    END IF;
    
    #ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked
	INSERT IGNORE INTO Temp_UnlinkedAssociation (CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
	WITH CTE_AssociationRemove AS (
		SELECT asRe.ToCTSCustID AS CTSCustID_Aff
			,  asRe.CreatedDate
		FROM CTS_DataCenter.AssociationRemove AS asRe 
		WHERE asRe.FromCTSCustID = ip_CTSCustID
	)
	SELECT 	cte.CTSCustID_Aff
		,	tmp.AssociationType
		,	2 AS AssociationStatus
		,	cte.CreatedDate
	FROM CTE_AssociationRemove AS cte
		INNER JOIN Temp_Association AS tmp ON cte.CTSCustID_Aff = tmp.CTSCustID_Aff;        
        
	INSERT IGNORE INTO Temp_UnlinkedAssociation (CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
	WITH CTE_AssociationRemove AS (
		SELECT asRe.FromCTSCustID AS CTSCustID_Aff
			,  asRe.CreatedDate
		FROM CTS_DataCenter.AssociationRemove AS asRe 
		WHERE asRe.ToCTSCustID = ip_CTSCustID
	)
	SELECT 	cte.CTSCustID_Aff
		,	tmp.AssociationType
		,	2 AS AssociationStatus
		,	cte.CreatedDate
	FROM CTE_AssociationRemove AS cte
		INNER JOIN Temp_Association AS tmp ON cte.CTSCustID_Aff = tmp.CTSCustID_Aff;
        
	DELETE cuAs 
	FROM Temp_Association AS cuAs 
	WHERE cuAs.CTSCustID_Aff IN (SELECT CTSCustID_Aff FROM Temp_UnlinkedAssociation);
        
	INSERT IGNORE INTO Temp_Association(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
	SELECT 	CTSCustID_Aff
		,	AssociationType
		,	AssociationStatus
		,	AssociationDate
	FROM Temp_UnlinkedAssociation;

     IF ip_AssociationStatus = 2 THEN
		DELETE 
        FROM Temp_Association 
        WHERE Temp_Association.AssociationStatus <> 2;
     END IF;
     
     IF ip_AssociationStatus = 1 THEN
		DELETE cuAs
        FROM Temp_Association  AS cuAs
            INNER JOIN Temp_UnlinkedAssociation AS un ON un.CTSCustID_Aff = cuAs.CTSCustID_Aff AND un.AssociationStatus = cuAs.AssociationStatus;
     END IF;     
  
     /* Insert data */
     INSERT IGNORE INTO Temp_AssociatedAccount(CTSCustID,CustID,CustSubID,SubscriberID,SubscriberName,SiteID,SiteName,UserName, UserName2,AccountStatusGroup,AccountStatusID,AccountStatusName,AssociationType, AssociationTypeName,AssociationStatus,AssociationDate)
     SELECT cust.CTSCustID
		,	cust.CustID
        ,	cust.CustSubID
		,	cust.SubscriberID
        ,	maSu.SubscriberName
        ,	cust.SiteID
        ,	cust.Site AS SiteName
        ,	cust.UserName
        ,	cust.UserName2
        ,	sta1.PriorityOrder AS AccountStatusGroup
        ,	sta1.ItemID AS AccountStatusID
		,   sta1.ItemName AS AccountStatusName
        ,	cuAs.AssociationType
        ,	sta.ItemName AS AssociationTypeName 
        ,	cuAs.AssociationStatus
        ,	cuAs.AssociationDate
     FROM Temp_Association AS cuAs
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cust ON cuAs.CTSCustID_Aff = cust.CTSCustID
        STRAIGHT_JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 2 AND sta.ItemID = cuAs.AssociationType 
	    STRAIGHT_JOIN CTS_DataCenter.StaticList AS sta1 ON sta1.ListID = 1 AND sta1.ItemID = cust.CustStatusID
        STRAIGHT_JOIN CTS_DataCenter.MappingSubscriberSite AS maSu ON maSu.SubscriberID = cust.SubscriberID AND maSu.SiteID = cust.SiteID
        STRAIGHT_JOIN CTS_DataCenter.SubscriberGroup AS sg ON sg.SubscriberGroupID = maSu.SubscriberGroupID AND sg.IsActive = 1
    ON DUPLICATE KEY UPDATE AssociationTypeName =  CONCAT(Temp_AssociatedAccount.AssociationTypeName, ', ', sta.ItemName),
							AssociationDate = LEAST(Temp_AssociatedAccount.AssociationDate, cuAs.AssociationDate);

    /* Get category */         
    IF EXISTS (SELECT 1 FROM Temp_CategoryID WHERE CategoryID = 0) THEN
		INSERT IGNORE INTO Temp_Classification(CTSCustID, ParentID)
		SELECT	tmpAcc.CTSCustID
			,	0
		FROM Temp_AssociatedAccount AS tmpAcc
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CTSCustID = tmpAcc.CTSCustID 
		WHERE cate.CTSCustID IS NULL;
    END IF;
    
    INSERT IGNORE INTO Temp_Classification(CTSCustID, ParentID, CategoryIDs, CategoryNames,IsProbation)
	SELECT	tmpAcc.CTSCustID
		,	cc.ParentID -- Each Customer has only 1 ParentID
		,	GROUP_CONCAT(DISTINCT cate.CategoryID SEPARATOR ',') 
        ,	GROUP_CONCAT(DISTINCT cc.CategoryName SEPARATOR ',')
		,	MAX(cc.IsProbation)
	FROM	Temp_AssociatedAccount AS tmpAcc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CTSCustID = tmpAcc.CTSCustID
        INNER JOIN Temp_CategoryID AS tmpCate ON tmpCate.CategoryID = cate.CategoryID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = tmpCate.CategoryID 
	GROUP BY tmpAcc.CTSCustID, cc.ParentID;
    
    /* Update IsFiltered */
    UPDATE 	Temp_AssociatedAccount AS tmpAcc
		INNER JOIN Temp_SubscriberID AS tmpSub ON tmpSub.SubscriberID = tmpAcc.SubscriberID
        INNER JOIN Temp_AccountStatusID AS tmpSt ON tmpSt.AccountStatusID = tmpAcc.AccountStatusID
        INNER JOIN Temp_Classification AS tmpCS ON tmpCS.CTSCustID = tmpAcc.CTSCustID
    SET tmpAcc.IsFiltered = 1;

	/* Return data */
	SELECT	tmpAcc.CTSCustID
		,	tmpAcc.CustId
        , 	tmpAcc.CustSubId
		,	tmpAcc.SubscriberID
		, 	tmpAcc.SubscriberName
        , 	tmpAcc.SiteID
		, 	tmpAcc.SiteName
		, 	tmpAcc.UserName
		, 	tmpAcc.UserName2
		,	tmpAcc.AccountStatusGroup AS StatusGroup
		, 	tmpAcc.AccountStatusID AS StatusID
		, 	tmpAcc.AccountStatusName AS StatusName
		, 	tmpAcc.AssociationTypeName
        , 	tmpAcc.AssociationStatus
		, 	tmpAcc.AssociationDate
		,	tmpCS.ParentID AS ParentIDs
		,	tmpCS.CategoryIDs AS CategoryIDs
		,	tmpCS.CategoryNames AS CategoryNames
		,	tmpCS.IsProbation AS IsProbation
		,	t.GroupIDList AS GroupIDs
		,	t.OriginGroupIDList AS OriginGroupIDs
	FROM Temp_AssociatedAccount AS tmpAcc
		INNER JOIN Temp_Classification AS tmpCS ON tmpCS.CTSCustID = tmpAcc.CTSCustID
		LEFT JOIN Temp_CustomerGroup AS t ON tmpAcc.CustID = t.CustID
	WHERE tmpAcc.IsFiltered = 1
	ORDER BY  tmpAcc.SubscriberName ASC, tmpAcc.AssociationStatus ASC , tmpAcc.AccountStatusGroup ASC, tmpAcc.AccountStatusID ASC,  tmpAcc.AssociationDate DESC, tmpAcc.CTSCustID ASC
	LIMIT ip_Take
	OFFSET ip_Skip; 
 
	SELECT COUNT(1) 
	INTO op_TotalItems
	FROM Temp_AssociatedAccount
    WHERE IsFiltered = 1; 
END$$
DELIMITER ;