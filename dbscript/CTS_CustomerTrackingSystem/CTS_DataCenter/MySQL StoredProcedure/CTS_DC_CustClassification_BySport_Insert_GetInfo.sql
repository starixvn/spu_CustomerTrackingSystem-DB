/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_Insert_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Insert_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_CustInfo				JSON
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
			
		Param's Expanation:
			- ip_InputFlowID:
			- ip_CustInfo:
		
		Revisions: 
			- 20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
*/
	DECLARE CONST_CATEID_SPECIALCC 							INT;
	DECLARE CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL			INT;
	DECLARE CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC		INT;
	
	SET CONST_CATEID_SPECIALCC								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
	SET CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL				= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL');
	SET CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC');

	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID						BIGINT UNSIGNED
		, 	CTSCustID					BIGINT 
		,	SubscriberID 				INT UNSIGNED
		,	RoleID						INT	
		,	IsLicenseeVIP				TINYINT(1) DEFAULT 0
		,	SportID						SMALLINT UNSIGNED
		,	Remark						VARCHAR(500)
		,	CreatedBy					INT UNSIGNED
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	
		,	DWCategoryID				INT UNSIGNED
		,	DWCategoryGroupID			INT UNSIGNED
		,	OldCategoryID 				INT UNSIGNED
		,	OldCategoryGroupID			INT UNSIGNED
		,	NewCategoryID				INT UNSIGNED
		, 	NewCategoryGroupID			INT UNSIGNED
		,	CategoryPriority			SMALLINT UNSIGNED
		,	CustomerClassPriority		SMALLINT UNSIGNED
		,	IsDataChanged				TINYINT(1) DEFAULT 1 /*0: No change category => No Action*/
		,	OldTargetCC					INT
		,	TargetCC					INT
		, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/
		,	PerformanceTime				DATETIME(3)
		,	SpecialCC					INT
		,	SourceTypeID      			SMALLINT
		,	IsReturnData				TINYINT(1) DEFAULT 1			
		, 	INDEX IX_Temp_NewCC_BySport_CustID_DWCategoryID (CustID, DWCategoryID)  
		,	PRIMARY KEY (CustID, SportID)
	); 

	IF ip_InputFlowID = CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC THEN 
		
		INSERT INTO Temp_NewClassification (
				CustID, CTSCustID, SubscriberID, RoleID, Remark, DWCategoryID, NewCategoryID, SportID, CreatedBy
			, 	IsLicenseeVIP, TargetCC, IsDataChanged, IsReturnData)
		SELECT 	tmpJs.CustID, tmpJs.CTSCustID, tmpJs.SubscriberID, cus.RoleID, tmpJs.Remark
			,	CONST_CATEID_SPECIALCC AS DWCategoryID
			,	CONST_CATEID_SPECIALCC AS NewCategoryID
			, 	tmpJs.SportID, tmpJs.CreatedBy, tmpJs.IsLicenseeVIP, tmpJs.TargetCC
			,	(CASE WHEN cls.CustID IS NULL THEN 1 ELSE 0 END) AS IsDataChanged
			,	(CASE WHEN cls.CustID IS NOT NULL THEN 0 ELSE 1 END) AS IsReturnData
		FROM JSON_TABLE(ip_CustInfo,
						 "$[*]" COLUMNS(
												CustID 			BIGINT UNSIGNED		PATH "$.CustID"
											,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
											,	SubscriberID 	INT UNSIGNED		PATH "$.SubscriberID"
											,	IsLicenseeVIP	TINYINT(1)			PATH "$.IsLicenseeVIP"            
											,	SportID			SMALLINT UNSIGNED	PATH "$.SportID"            
											,	TargetCC		INT					PATH "$.CustomerClass"            
											,	CreatedBy 		INT UNSIGNED		PATH "$.CreatedBy"          
											,	Remark			VARCHAR(500)		PATH "$.Remark"
										 )) AS tmpJs
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cls ON cls.CustID = tmpJs.CustID AND cls.CategoryID = CONST_CATEID_SPECIALCC;

	ELSEIF ip_InputFlowID = CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL THEN 
	
		INSERT IGNORE INTO Temp_NewClassification(
				CTSCustID, CustID, SportID, DWCategoryID, TurnoverRM, WinlossRM, BetCount
			, 	ActiveDays, PerformanceTime, SpecialCC)
		SELECT DISTINCT cus.CTSCustID
					,	tmpJs.CustID
					, 	tmpJs.SportID
					, 	tmpJs.DWCategoryID
					, 	tmpJs.TurnoverRM
					, 	tmpJs.WinlossRM
					, 	tmpJs.BetCount
					, 	tmpJs.ActiveDays
					,	tmpJs.PerformanceTime
					,	sp.CustomerClass AS SpecialCC
		FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 					BIGINT UNSIGNED		PATH "$.CustId"
											, 	SportID					SMALLINT UNSIGNED	PATH "$.SportGroup"
											, 	DWCategoryID			INT UNSIGNED		PATH "$.CategoryId"
											, 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
											, 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
											, 	BetCount				BIGINT				PATH "$.BetCount"
											, 	ActiveDays				INT					PATH "$.ActiveDays"		
											,	PerformanceTime			DATETIME(3)			PATH "$.PerformanceTime"
										   )) AS tmpJs
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpJs.CustID = cus.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass_BySport AS sp ON tmpJs.CustID = sp.CustID AND tmpJs.SportID = sp.SportID
		WHERE tmpJs.DWCategoryID <> 0;
		
	END IF;



END$$
DELIMITER ;