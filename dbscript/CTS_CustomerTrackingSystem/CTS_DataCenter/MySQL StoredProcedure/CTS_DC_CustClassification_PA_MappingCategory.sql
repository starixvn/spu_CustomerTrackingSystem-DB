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
			- 20220328@Aries.Nguyen: Created [Redmine ID: #170468]
            - 20220505@Aries.Nguyen: Classification History - Wrong store Source Type for mark/remove PA [Redmine ID: #172401]
			- 20220426@Casey.Huynh: Return CreatedBy [Redmine ID: #171512]
            - 20220519@Casey.Huynh: Renovate PA Process [Redmine ID: #172061]
            - 20220627@Casey.Huynh: Classify Match Monitor Results, Add MatchID [Redmine ID: #174218]
            
		Param's Explanation (filtered by):      
			CALL CTS_DC_CustClassification_PA_MappingCategory ('Category','[{"CustID": 3679910,"ReasonID": 3679910,"WinlossStatus": 1,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10, "MatchID": 1}]');
	*/
    DECLARE CONST_ROBOT				SMALLINT DEFAULT 163;
    DECLARE CONST_ROBOT_LOSING		SMALLINT DEFAULT 164;

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
        ,	IsProbationStatus		BOOLEAN  NULL
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
        ,	IsDataChanged			BOOLEAN DEFAULT 0 	# 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0)
        ,	DataChangeType			TINYINT DEFAULT 0	# 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE
        ,	OldCategoryID		    SMALLINT
        ,	SpecialCC				SMALLINT UNSIGNED
        ,	TVSRequestID			INT NULL
        ,	LastModifiedDate		DATETIME
        ,	IsFromOldPA				BOOLEAN
        ,	PinCTSCustID			BIGINT UNSIGNED			
        ,	ActionType				TINYINT DEFAULT 0	#0:INSERT, 1:UPDATE
        ,	MatchID					INT
        , 	PRIMARY KEY PK_Temp_PA(CustID,InputCategoryID)  
        ,	INDEX IX_Temp_PA(IsDataChanged,LastModifiedDate)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotWinlossStatus;    
	CREATE TEMPORARY TABLE Temp_RobotWinlossStatus(	
			CustID					BIGINT UNSIGNED PRIMARY KEY
        , 	WinlossStatus			SMALLINT /*LOSING  = 0 (PROBATION), WINNING = 2 (NOT PROBATION);*/
	);
   
    IF ip_InputType = 'Category' THEN    
        INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, InputCategoryID, InputCategoryGroup,  IsLicensee, CreatedBy, Remark, IsDirectPA
			, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsDataChanged, SpecialCC, IsProbation, RelevantCategoryID, LastModifiedDate, PinCTSCustID, MatchID)
		SELECT 	DISTINCT tmpJs.CustID
			,	tmpJs.CTSCustID
			,	tmpJs.RoleID
			, 	tmpJs.SubscriberID
			,	tmpJs.CategoryID
			,	tmpJs.CategoryGroup
			,	tmpJs.IsLicensee
			,	tmpJs.CreatedBy 
			,	(CASE WHEN tmpJs.MatchID IS NOT NULL THEN MatchID ELSE tmpJs.Remark END) AS Remark
			,	tmpJs.IsDirectPA
			, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
			, 	tmpJs.TurnoverRM
			, 	tmpJs.WinlossRM 
			, 	tmpJs.BetCount 
			, 	tmpJs.ActiveDays
			,	tmpJs.IsFromTVS
			,	tmpJs.IsFromTW
			,	tmpJs.IsFromCTS
			,	tmpJs.IsDataChanged
            ,	sp.CustomerClass
			,	(CASE 	WHEN tmpJs.WinlossStatus = 0 THEN 1  # PROBATION
                        ELSE 0  # NOT PROBATION (WinlossStatus IN (1, NULL, 2))
                        END) AS IsProbation			
            ,	cat.RelevantCategoryID
            ,	tmpJs.LastModifiedDate
            ,	pin.CTSCustID
			,	tmpJs.MatchID
		FROM JSON_TABLE(ip_CustInfo,
			"$[*]" COLUMNS(
					CustID 			BIGINT UNSIGNED		PATH "$.CustID"
				,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
				,	RoleID 			INT					PATH "$.RoleID" 
				,	SubscriberID 	BIGINT UNSIGNED		PATH "$.SubscriberID"
				,	CategoryID		BIGINT UNSIGNED		PATH "$.CategoryID"
				,	CategoryGroup	BIGINT UNSIGNED		PATH "$.CategoryGroup"
				,	IsLicensee		BOOLEAN				PATH "$.IsLicensee"
				, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
				, 	Remark			VARCHAR(500)		PATH "$.Remark"
				, 	IsDirectPA		BOOLEAN				PATH "$.IsDirectPA"
				,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"
				, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
				, 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
				, 	IsFromCTS		BOOLEAN 			PATH "$.IsFromCTS"
				, 	IsDataChanged	BOOLEAN 			PATH "$.IsDataChanged"
				, 	LastModifiedDate	DATETIME 		PATH "$.LastModifiedDate"
                , 	MatchID				INT 			PATH "$.MatchID"	
		)) AS tmpJs
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on tmpJs.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CTSCustID = sp.CTSCustID 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.CategoryID;		
    
		INSERT INTO Temp_RobotWinlossStatus(CustID, WinlossStatus)
		SELECT DISTINCT t.CustID
			,	CASE 
					WHEN cc.IsPAProbation = 1 THEN 0
					ELSE 2
				END AS WinlossStatus
		FROM Temp_PA AS t
			INNER JOIN CTSCustomerClassification AS c ON t.CustID = c.CustID
            INNER JOIN CustomerCategory AS cc ON c.CategoryID = cc.CategoryID
		LIMIT 1;
		
		UPDATE Temp_PA AS t
			INNER JOIN Temp_RobotWinlossStatus AS r ON t.CustID = r.CustID
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
		INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, InputCategoryID, InputCategoryGroup,  IsLicensee, CreatedBy, Remark, IsDirectPA
			, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, SpecialCC, IsProbation, RelevantCategoryID, TVSRequestID, ReasonID, PinCTSCustID)
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
            ,	sp.CustomerClass
			,	(CASE 	WHEN tmpJs.WinlossStatus = 0 THEN 1  # PROBATION
                        ELSE 0  # NOT PROBATION (WinlossStatus IN (1, NULL, 2))
                        END) AS IsProbation			
            ,	tmpLtr.RelevantCategoryID
            ,	tmpJs.TVSRequestID
            ,	tmpJs.ReasonID
            ,	pin.CTSCustID
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
                , 	TVSRequestID	INT 				PATH "$.TVSRequestID"
                , 	Remark			VARCHAR(500) 		PATH "$.Remark"
		)) AS tmpJs
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on cus.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CTSCustID = sp.CTSCustID,
            LATERAL (SELECT cat.CategoryGroup, cat.RelevantCategoryID FROM CTS_DataCenter.CustomerCategory AS cat WHERE cat.ReasonID = tmpJs.ReasonID LIMIT 1) tmpLtr;
		
        INSERT INTO Temp_RobotWinlossStatus(CustID, WinlossStatus)
		SELECT DISTINCT t.CustID
			,	CASE 
					WHEN cc.IsPAProbation = 1 THEN 0
					ELSE 2
				END AS WinlossStatus
		FROM Temp_PA AS t
			INNER JOIN CTSCustomerClassification AS c ON t.CustID = c.CustID
            INNER JOIN CustomerCategory AS cc ON c.CategoryID = cc.CategoryID
		LIMIT 1;
		
		UPDATE Temp_PA AS t
			INNER JOIN Temp_RobotWinlossStatus AS r ON t.CustID = r.CustID
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
                
		CALL CTS_DC_CustClassification_PA_RemoveOldTVSRequest();        
	END IF;
    
END$$
DELIMITER ;