/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService,ctsAPIAdmin,ctsAPI,ctsWebAdmin,ctsWeb" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_PA_MappingCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_MappingCategory`(
		IN 		ip_InputType	VARCHAR(20)	#"Category, Reason"
    ,	IN 		ip_CustInfo 	JSON
	
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220328@Aries.Nguyen
		Task: Add new category/class for PA Probation [Redmine ID: #170468]
		DB: CTS_DataCenter
        
		Original:
		Revisions:
			- 20220328@Aries.Nguyen: 	Created [Redmine ID: #170468]
			- 20220505@Aries.Nguyen: 	Classification History - Wrong store Source Type for mark/remove PA [Redmine ID: #172401]
			- 20220426@Casey.Huynh: 	Return CreatedBy [Redmine ID: #171512]
			- 20220519@Casey.Huynh: 	Renovate PA Process [Redmine ID: #172061]
			- 20220627@Casey.Huynh: 	Classify Match Monitor Results, Add MatchID [Redmine ID: #174218]
			- 20220913@Casey.Huynh: 	Update Remark [Redmine ID: #176976]
			- 20230404@Victoria.Le		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeID [Redmine ID: #185319] 
			- 20230601@Victoria.Le:		Add TVSRequestID <> 0 for TVSRequestID IS NOT NULL [Redmine ID: #189023]
            - 20240306@Thomas.Nguyen:	Add log table for tracking TVS void request [Redmine ID: #201993]
			- 20240321@Casey.Huynh: 	Classify Danger Score, Add GroupPriority [Redmine ID: #201358]
            - 20240423@Thomas.Nguyen: 	Classify initial group betting - Add SportGroupID = 150 [Redmine ID: #200854]

		Param's Explanation (filtered by):      
			CALL CTS_DC_CustClassification_PA_MappingCategory ('Category','[{"CustID": 3679910,"ReasonID": 3679910,"WinlossStatus": 1,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10, "MatchID": 1}]');
	*/

    #=======================================================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
		/*Cust info*/
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED DEFAULT 0
        ,	RoleID					INT
        , 	SubscriberID			INT DEFAULT 0
        ,	IsLicensee				BOOLEAN
        ,	Remark 					VARCHAR(500)        
        ,	CreatedBy 				INT UNSIGNED
        
        /*Data warehouse, mainDB  info*/
        , 	WinlossStatus			SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        
        /*Get Mapping Value*/
		, 	InputCategoryID		    SMALLINT UNSIGNED
        ,	InputCategoryGroup     	SMALLINT UNSIGNED    
        , 	CategoryID		   		SMALLINT UNSIGNED
        , 	ReasonID		   		INT
        ,	CategoryGroup     		SMALLINT UNSIGNED
        ,	IsProbation	     		BOOLEAN
        ,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
        , 	ToEvidenceID			SMALLINT
        , 	RelevantCategoryID		SMALLINT UNSIGNED
        ,	RelevantCategoryGroup   SMALLINT UNSIGNED
        ,	RelevantIsProbation	   	BOOLEAN
		,	IsDirectPA				BOOLEAN        
        ,	IsFromTVS				BOOLEAN DEFAULT 0
        ,	IsFromTW				BOOLEAN DEFAULT 0
        ,	IsFromCTS				BOOLEAN DEFAULT 0
        ,	IsFromAI				BOOLEAN DEFAULT 0
        ,	IsDataChanged			BOOLEAN DEFAULT 0 	# 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0)
        ,	DataChangeType			TINYINT DEFAULT 0	# 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE
        ,	OldCategoryID		    SMALLINT
        ,	SpecialCC				SMALLINT UNSIGNED
        ,	TVSRequestID			BIGINT UNSIGNED
        ,	LastModifiedDate		DATETIME
        ,	IsFromOldPA				BOOLEAN
        ,	PinCTSCustID			BIGINT UNSIGNED			
        ,	ActionType				TINYINT DEFAULT 0	#0:INSERT, 1:UPDATE
        ,	MatchID					INT
		,	IsParlay 				BIT DEFAULT NULL
		,	SportType				SMALLINT DEFAULT NULL 
		,	IssueTypeID 			TINYINT DEFAULT NULL
        ,	GroupPriority			SMALLINT UNSIGNED
        ,	ParentID				SMALLINT UNSIGNED
        , 	PRIMARY KEY PK_Temp_PA(CustID,InputCategoryID)  
        ,	INDEX IX_Temp_PA(IsDataChanged,LastModifiedDate)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PAWinlossStatus;    
	CREATE TEMPORARY TABLE Temp_PAWinlossStatus(	
			CustID					BIGINT UNSIGNED PRIMARY KEY
        , 	WinlossStatus			SMALLINT /*LOSING  = 0 (PROBATION), WINNING = 2 (NOT PROBATION);*/
	);
    
    #======================================
	DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCategory;
    CREATE TEMPORARY TABLE Temp_SpecialCategory (
			CategoryID 		SMALLINT UNSIGNED PRIMARY KEY
        ,	CustomerClass	SMALLINT UNSIGNED
        ,	Priorty 		SMALLINT
        
        ,	INDEX IX_Temp_SpecialCategory_CustomerClass(CustomerClass)
    );
	
    #======================================
	DROP TEMPORARY TABLE IF EXISTS Temp_MappingReason;
    CREATE TEMPORARY TABLE Temp_MappingReason (
			ReasonID		INT
        ,	MappingReasonID	INT
    );
	
    #================4x======================================
    INSERT INTO Temp_SpecialCategory( CategoryID, CustomerClass, Priorty)
    SELECT	cat.CategoryID
		,	cat.CustomerClass
		,	cat.Priority
	FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.Priority = 55; # Handle for 4x
	
	INSERT INTO Temp_MappingReason (ReasonID, MappingReasonID)
	VALUES 	(39, 3900)		-- Abnormal
		,	(100, 10000)	-- Group Betting
		,	(101, 10100)	-- Hedging
		,	(102, 10200)	-- Arbitrage
		,	(103, 10300)	-- Fixed Game
		,	(104, 10400)	-- AB Bet
		,	(105, 10500)	-- Robot User
		,	(106, 10600)	-- Irrigation Bet
		,	(107, 10700)	-- System Formula Bet
	;
    
    IF ip_InputType = 'Category' THEN    
        INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, InputCategoryID, InputCategoryGroup,  IsLicensee, CreatedBy, Remark, IsDirectPA
			, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsDataChanged, SpecialCC, IsProbation, RelevantCategoryID
			, LastModifiedDate, PinCTSCustID, MatchID, TVSRequestID, IsParlay, SportType, IssueTypeID, GroupPriority, ParentID)
		SELECT 	DISTINCT tmpJs.CustID
			,	tmpJs.CTSCustID
			,	tmpJs.RoleID
			, 	tmpJs.SubscriberID
			,	tmpJs.CategoryID
			,	tmpJs.CategoryGroup
			,	tmpJs.IsLicensee
			,	tmpJs.CreatedBy 
			,	(CASE WHEN tmpJs.MatchID IS NOT NULL THEN CONCAT('Auto MatchID: ', MatchID) ELSE tmpJs.Remark END) AS Remark
			,	tmpJs.IsDirectPA
			, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
			, 	tmpJs.TurnoverRM
			, 	tmpJs.WinlossRM 
			, 	tmpJs.BetCount 
			, 	tmpJs.ActiveDays
			,	tmpJs.IsFromTVS
			,	tmpJs.IsFromTW
			,	tmpJs.IsFromCTS
            ,	tmpJs.IsFromAI
			,	tmpJs.IsDataChanged
            ,	sp.CustomerClass
			,	(CASE 	WHEN tmpJs.WinlossStatus = 0 THEN 1  # PROBATION
                        ELSE 0  # NOT PROBATION (WinlossStatus IN (1, NULL, 2))
                        END) AS IsProbation			
            ,	cat.RelevantCategoryID
            ,	tmpJs.LastModifiedDate
            ,	pin.CTSCustID
			,	tmpJs.MatchID
			,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
					 ELSE tmpJs.TVSRequestID END
			,	tmpJs.IsParlay
			,	tmpJs.SportType
			,	tmpJs.IssueTypeID
            ,	cat.GroupPriority
            ,	cat.ParentID
		FROM JSON_TABLE(ip_CustInfo,
			"$[*]" COLUMNS(
							CustID 				BIGINT UNSIGNED		PATH "$.CustID"
						,	CTSCustID 			BIGINT UNSIGNED		PATH "$.CTSCustID"
						,	RoleID 				INT					PATH "$.RoleID" 
						,	SubscriberID 		BIGINT UNSIGNED		PATH "$.SubscriberID"
						,	CategoryID			BIGINT UNSIGNED		PATH "$.CategoryID"
						,	CategoryGroup		BIGINT UNSIGNED		PATH "$.CategoryGroup"
						,	IsLicensee			BOOLEAN				PATH "$.IsLicensee"
						, 	CreatedBy			INT UNSIGNED		PATH "$.CreatedBy"
						, 	Remark				VARCHAR(500)		PATH "$.Remark"
						, 	IsDirectPA			BOOLEAN				PATH "$.IsDirectPA"
						,	WinlossStatus		SMALLINT 			PATH "$.WinlossStatus" 
						,	TurnoverRM			DECIMAL(20,4)		PATH "$.TurnoverRM"
						,	WinlossRM			DECIMAL(20,4) 		PATH "$.WinlossRM"
						, 	BetCount			BIGINT 				PATH "$.BetCount"
						, 	ActiveDays			INT 				PATH "$.ActiveDays"
						, 	IsFromTVS			BOOLEAN 			PATH "$.IsFromTVS"
						, 	IsFromTW			BOOLEAN 			PATH "$.IsFromTW"
						, 	IsFromCTS			BOOLEAN 			PATH "$.IsFromCTS"
                        , 	IsFromAI			BOOLEAN 			PATH "$.IsFromAI"
						, 	IsDataChanged		BOOLEAN 			PATH "$.IsDataChanged"
						, 	LastModifiedDate	DATETIME 			PATH "$.LastModifiedDate"
						, 	MatchID				INT 				PATH "$.MatchID"	
						, 	TVSRequestID		BIGINT UNSIGNED		PATH "$.TVSRequestID"
						,	IsParlay			BOOLEAN 			PATH "$.IsParlay"
						,	SportType			SMALLINT 			PATH "$.SportType"
						,	IssueTypeID			TINYINT 			PATH "$.IssueTypeID"
		)) AS tmpJs
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on tmpJs.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CTSCustID = sp.CTSCustID AND sp.CustomerClass NOT IN (SELECT DISTINCT tmp.CustomerClass FROM Temp_SpecialCategory AS tmp)
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.CategoryID;		

		INSERT IGNORE INTO Temp_PAWinlossStatus(CustID, WinlossStatus)
		SELECT DISTINCT t.CustID
			,	CASE 
					WHEN cc.IsDangerProbation = 1 THEN 0
					ELSE 2
				END AS WinlossStatus
		FROM Temp_PA AS t
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS c ON t.CustID = c.CustID
            INNER JOIN CustomerCategory AS cc ON c.CategoryID = cc.CategoryID
		WHERE c.SportGroupID IN (0, 150);
		
		UPDATE Temp_PA AS t
			INNER JOIN Temp_PAWinlossStatus AS r ON t.CustID = r.CustID
		SET t.WinlossStatus = r.WinlossStatus,
			t.IsProbation = (CASE 	
								WHEN r.WinlossStatus = 0 THEN 1  # LOSING
								ELSE 0  # NOT LOSING
							END)
		WHERE t.WinlossStatus = 1;

		UPDATE Temp_PA AS tmpPA,
		LATERAL(SELECT 	cat.CategoryGroup
					,	cat.CustomerClass
					,	cat.ABIDangerLevel_Licensee
					,	cat.ABIDangerLevel_Credit
					,	cat.EvidenceID_Licensee
					,	cat.EvidenceID_Credit
					,	cat.RelevantCategoryID
				FROM CTS_DataCenter.CustomerCategory AS cat 
				WHERE cat.CategoryID IN (tmpPA.InputCategoryID, tmpPA.RelevantCategoryID) AND cat.IsProbation = tmpPA.IsProbation LIMIT 1) AS tmpCat
		SET 	tmpPA.CategoryGroup = tmpCat.CategoryGroup	
			,	tmpPA.CategoryID = tmpCat.CategoryGroup
			,	tmpPA.TargetCC = (CASE 	WHEN tmpPA.SpecialCC IS NOT NULL THEN tmpPA.SpecialCC ELSE IFNULL(tmpCat.CustomerClass,-99) END)
			,	tmpPA.TargetDangerLevel = (CASE WHEN tmpPA.IsLicensee = 1 THEN tmpCat.ABIDangerLevel_Licensee
												WHEN tmpPA.IsLicensee = 0 THEN tmpCat.ABIDangerLevel_Credit END) 
			,	tmpPA.ToEvidenceID = (CASE 	WHEN tmpPA.IsLicensee = 1 THEN tmpCat.EvidenceID_Licensee
											WHEN tmpPA.IsLicensee = 0 THEN tmpCat.EvidenceID_Credit
											ELSE NULL END)
			,	tmpPA.RelevantCategoryID = tmpCat.RelevantCategoryID;
	
		UPDATE Temp_PA AS tmpPA,
		LATERAL(SELECT 	cat.CategoryGroup
					,	cat.IsProbation
				FROM CTS_DataCenter.CustomerCategory  AS cat 
				WHERE cat.CategoryID = tmpPA.RelevantCategoryID LIMIT 1) AS tmpCat
		SET 	tmpPA.RelevantCategoryGroup = tmpCat.CategoryGroup	
			,	tmpPA.RelevantCategoryID = tmpCat.CategoryGroup
			,	tmpPA.RelevantIsProbation = tmpCat.IsProbation;	            
    END IF;   
 
    IF ip_InputType = 'Reason' THEN
		INSERT INTO CTS_DataCenter.TVSVoidRequest_Log(TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate,CreatedTime,IsParlay,SportType,IssueTypeID)
		WITH CTECustInfo AS (
			SELECT	tmpJs.TVSRequestID AS TVSRequestID
				,	tmpJs.CustID AS CustID
				,	CASE WHEN tmpJs.IssueTypeID = 13 AND tmpR.ReasonID IS NOT NULL THEN tmpR.MappingReasonID
						ELSE tmpJs.ReasonID END AS ReasonID
				,	tmpJs.CreatedBy AS CreatedBy
				,	tmpJs.IsParlay AS IsParlay
				,	tmpJs.SportType AS SportType
				,	tmpJs.IssueTypeID AS IssueTypeID
			FROM JSON_TABLE(ip_CustInfo,
				"$[*]" COLUMNS(
						CustID 			BIGINT UNSIGNED		PATH "$.CustID"
					,	ReasonID		INT 				PATH "$.ReasonID"
					, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
					, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
					, 	TVSRequestID	BIGINT UNSIGNED		PATH "$.TVSRequestID"
					,	IsParlay		BOOLEAN 			PATH "$.IsParlay"
					,	SportType		SMALLINT 			PATH "$.SportType"
					,	IssueTypeID		TINYINT 			PATH "$.IssueTypeID"
				)) AS tmpJs
				LEFT JOIN Temp_MappingReason AS tmpR ON tmpR.ReasonID = tmpJs.ReasonID
			WHERE tmpJs.IsFromTVS = 1
		)
		SELECT	TVSRequestID
			,	GROUP_CONCAT(DISTINCT CustID)
			,	ReasonID
			,	CreatedBy
			,	NOW() AS CreatedDate
			,	CURRENT_TIMESTAMP(3) AS CreatedTime
			,	IsParlay
			,	SportType
			,	IssueTypeID
		FROM CTECustInfo AS cte
		GROUP BY TVSRequestID, ReasonID, CreatedBy, IsParlay, SportType, IssueTypeID;

		INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, InputCategoryID, InputCategoryGroup,  IsLicensee, CreatedBy, Remark, IsDirectPA
			, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, SpecialCC, IsProbation, RelevantCategoryID
			, TVSRequestID, ReasonID, PinCTSCustID, IsParlay, SportType, IssueTypeID, GroupPriority, ParentID)
		SELECT	DISTINCT tmpJs.CustID
			,	cus.CTSCustID
			,	cus.RoleID
			, 	cus.SubscriberID
			,	tmpLtr.CategoryGroup AS InputCategoryID
			,	tmpLtr.CategoryGroup AS InputCategoryGroup
			,	cus.IsLicensee
			,	tmpJs.CreatedBy 
			,	tmpJs.Remark
			,	tmpJs.IsDirectPA
			, 	tmpJs.WinlossStatus 
			, 	tmpJs.TurnoverRM
			, 	tmpJs.WinlossRM 
			, 	tmpJs.BetCount 
			, 	tmpJs.ActiveDays
			,	tmpJs.IsFromTVS
			,	tmpJs.IsFromTW
			,	tmpJs.IsFromCTS
            ,	tmpJs.IsFromAI
            ,	sp.CustomerClass
			,	(CASE 	WHEN tmpJs.WinlossStatus = 0 THEN 1  # PROBATION
                        ELSE 0  # NOT PROBATION (WinlossStatus IN (1, NULL, 2))
                        END) AS IsProbation			
            ,	tmpLtr.RelevantCategoryID
            ,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
					 ELSE tmpJs.TVSRequestID END
            ,	CASE WHEN tmpJs.IssueTypeID = 13 AND tmpR.ReasonID IS NOT NULL THEN tmpR.MappingReasonID
					 ELSE tmpJs.ReasonID END
            ,	pin.CTSCustID
			,	tmpJs.IsParlay
			,	tmpJs.SportType
			,	tmpJs.IssueTypeID
            ,	tmpLtr.GroupPriority
            ,	tmpLtr.ParentID
            FROM JSON_TABLE(ip_CustInfo,
			"$[*]" COLUMNS(
					CustID 			BIGINT UNSIGNED		PATH "$.CustID"
				,	ReasonID		INT 				PATH "$.ReasonID"
				, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
				, 	IsDirectPA		BOOLEAN				PATH "$.IsDirectPA"
				,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"
				, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
				, 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
				, 	IsFromCTS		BOOLEAN 			PATH "$.IsFromCTS"
                , 	IsFromAI		BOOLEAN 			PATH "$.IsFromAI"
                , 	TVSRequestID	BIGINT UNSIGNED		PATH "$.TVSRequestID"
                , 	Remark			VARCHAR(500) 		PATH "$.Remark"
				,	IsParlay		BOOLEAN 			PATH "$.IsParlay"
				,	SportType		SMALLINT 			PATH "$.SportType"
				,	IssueTypeID		TINYINT 			PATH "$.IssueTypeID"
		)) AS tmpJs
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON cus.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CTSCustID = sp.CTSCustID 
																	AND sp.CustomerClass NOT IN (SELECT DISTINCT tmp.CustomerClass FROM Temp_SpecialCategory AS tmp)
			LEFT JOIN Temp_MappingReason AS tmpR ON tmpR.ReasonID = tmpJs.ReasonID,
            LATERAL (SELECT cat.CategoryGroup, cat.RelevantCategoryID, cat.GroupPriority, cat.ParentID
					 FROM CTS_DataCenter.CustomerCategory AS cat 
					 WHERE cat.ReasonID = CASE WHEN tmpJs.IssueTypeID = 13 AND tmpR.ReasonID IS NOT NULL THEN tmpR.MappingReasonID
											   ELSE tmpJs.ReasonID END
					 LIMIT 1) tmpLtr;
    
		CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest(); 
        
        INSERT INTO Temp_PAWinlossStatus(CustID, WinlossStatus)
		SELECT DISTINCT t.CustID
			,	CASE 
					WHEN cc.IsDangerProbation = 1 THEN 0
					ELSE 2
				END AS WinlossStatus
		FROM Temp_PA AS t
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS c ON t.CustID = c.CustID
            INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON c.CategoryID = cc.CategoryID
		WHERE c.SportGroupID IN (0, 150);
		
		UPDATE Temp_PA AS t
			INNER JOIN Temp_PAWinlossStatus AS r ON t.CustID = r.CustID
		SET t.WinlossStatus = r.WinlossStatus,
			t.IsProbation = (CASE 	
								WHEN r.WinlossStatus = 0 THEN 1  # LOSING
								ELSE 0  # NOT LOSING
							END)
		WHERE t.WinlossStatus = 1;
        
        UPDATE Temp_PA AS tmpPA,
            LATERAL(SELECT 	cat.CategoryGroup
						,	cat.CustomerClass
						,	cat.ABIDangerLevel_Licensee
                        ,	cat.ABIDangerLevel_Credit
                        ,	cat.EvidenceID_Licensee
                        ,	cat.EvidenceID_Credit
                        ,	cat.RelevantCategoryID
					FROM CTS_DataCenter.CustomerCategory AS cat 
                    WHERE cat.CategoryID IN (tmpPA.InputCategoryID, tmpPA.RelevantCategoryID) AND cat.IsProbation = tmpPA.IsProbation LIMIT 1) AS tmpCat
			SET 	tmpPA.CategoryGroup = tmpCat.CategoryGroup	
				,	tmpPA.CategoryID = tmpCat.CategoryGroup
				,	tmpPA.TargetCC = (CASE 	WHEN tmpPA.SpecialCC IS NOT NULL THEN tmpPA.SpecialCC ELSE IFNULL(tmpCat.CustomerClass,-99) END)
                ,	tmpPA.TargetDangerLevel = (CASE WHEN tmpPA.IsLicensee = 1 THEN tmpCat.ABIDangerLevel_Licensee
													WHEN tmpPA.IsLicensee = 0 THEN tmpCat.ABIDangerLevel_Credit END) 
				,	tmpPA.ToEvidenceID = (CASE 	WHEN tmpPA.IsLicensee = 1 THEN tmpCat.EvidenceID_Licensee
												WHEN tmpPA.IsLicensee = 0 THEN tmpCat.EvidenceID_Credit
												ELSE NULL END)
				,	tmpPA.RelevantCategoryID = tmpCat.RelevantCategoryID;
        
		UPDATE Temp_PA AS tmpPA,
		LATERAL(SELECT 	cat.CategoryGroup
					,	cat.IsProbation
				FROM CTS_DataCenter.CustomerCategory  AS cat 
				WHERE cat.CategoryID = tmpPA.RelevantCategoryID LIMIT 1) AS tmpCat
		SET 	tmpPA.RelevantCategoryGroup = tmpCat.CategoryGroup	
			,	tmpPA.RelevantCategoryID = tmpCat.CategoryGroup
			,	tmpPA.RelevantIsProbation = tmpCat.IsProbation;       
	END IF;
    
END$$
DELIMITER ;