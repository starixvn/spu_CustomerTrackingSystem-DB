/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_Insert`(
		IN ip_ListCust					JSON
    ,	IN ip_CustomerClass				SMALLINT
	,	IN ip_Remark					VARCHAR(500)	
    ,	IN ip_CreatedBy					INT
)
    SQL SECURITY INVOKER
BEGIN
		/*
		Created:	20200905@Long.Luu
		Task:		Insert special customer class 
		DB:			CTS_DataCenter
		Original:

		Revisions: 
		   - 20200905@Long.Luu: Created [Redmine ID: #140996]
           - 20200908@Irena.Vo: Error MSG for the customers have VVIP before and Update CreatedFromFunction = 1 for special customer (Normal) [Redmine ID: #141020]
           - 20200921@Irena.Vo: Enhance SP & insert Probation Management flow. [Redmine ID: #141755]
		   - 20201229@Irena.Vo: Remove logic delete Probation List. Enhance logic get VVIP & Insert History Log. Enhance logic validate for RoleID = 1 [RedmineID: #145951]
           - 20210226@Irena.Vo: Update CategoryID from VVIP [RedmineID: #150454]
		   - 20210419@Irena.Vo: Get Category more [RedmineID: #153617]
		   - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
		   - 20210920@Aries.Nguyen: Split history log  [Redmine ID: #161890]
           - 20220805@Aries.Nguyen: New Category for CC14, 99, 101  [Redmine ID: #174219]         
		   - 20220817@Long.Luu: Rearrange CC's IDs [Redmine ID: #175698]
		   - 20240315@Thomas.Nguyen: Support list custs, add comment/log and special CC by sport [Redmine ID: #201360]

		Param's Explanation (filtered by):
			- Maximum Customer Class number for input param = 127 
		Example:
			- CALL CTS_DataCenter.CTS_DC_SpecialCustClass_Insert('[{"CustID":2237314,"CTSCustID":2485,"SubscriberID":130,"IsLicenseeVIP":0,"SportID":1}]',1001,'added by admin',8);
	*/    
    
    DECLARE	lv_CurrentDateTime		DATETIME DEFAULT CURRENT_TIME();
    DECLARE	lv_SPName 				VARCHAR(100) 	DEFAULT 'CTS_DC_SpecialCustClass_Insert';
	DECLARE lv_CreatedBy 			INT DEFAULT 10278938;
    DECLARE lv_LicVIPCC_Danger		SMALLINT UNSIGNED;
    DECLARE lv_LicVIPCC_Suspicious	SMALLINT UNSIGNED;
	DECLARE lv_SportID				SMALLINT UNSIGNED;

    DECLARE	CONST_LICVIP_DANGEROUSCATEGORY		INT DEFAULT 3;
    DECLARE	CONST_LICVIP_SUSPICIOUSCATEGORY		INT DEFAULT 4;   
  
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;    
	CREATE TEMPORARY TABLE Temp_Customer (	 
			CTSCustID			BIGINT UNSIGNED
		,	CustID				INT UNSIGNED
		,	SportID				SMALLINT UNSIGNED
		,	SubscriberID		INT		
		,	IsLicenseeVIP		TINYINT
		,	PRIMARY KEY (CustID, SportID)
		,	KEY IX_Temp_Customer_SportID (SportID)
    );    
 
    DROP TEMPORARY TABLE IF EXISTS Temp_NewCustomerClass;
    CREATE TEMPORARY TABLE Temp_NewCustomerClass(
			CTSCustID 				BIGINT UNSIGNED
		,	CustID					INT UNSIGNED
		,	SportID					SMALLINT UNSIGNED DEFAULT 0
        ,	SubscriberID			INT
        ,	CustomerClass			SMALLINT
        ,	IsDataChanged			BIT DEFAULT 0
        ,	Is4x					BIT DEFAULT 0        
        ,	Is4xDangerProbation		BIT DEFAULT 0
		,	PRIMARY KEY (CustID, SportID)
	);
    
    /* INIT */        
    SELECT CustomerClass
    INTO lv_LicVIPCC_Danger
    FROM CustomerCategory WHERE CategoryID = CONST_LICVIP_DANGEROUSCATEGORY;
    
    SELECT CustomerClass
    INTO lv_LicVIPCC_Suspicious
    FROM CustomerCategory WHERE CategoryID = CONST_LICVIP_SUSPICIOUSCATEGORY;

	INSERT INTO Temp_Customer(CTSCustID,CustID,SportID,SubscriberID,IsLicenseeVIP)
	SELECT	tmp.CTSCustID
		,	tmp.CustID
		,	tmp.SportID
		,	tmp.SubscriberID
		,	tmp.IsLicenseeVIP
	FROM JSON_TABLE(ip_ListCust, 
						'$[*]' COLUMNS (CTSCustID		BIGINT UNSIGNED			PATH '$.CTSCustID'
									,	CustID			INT UNSIGNED			PATH '$.CustID'
									,	SportID			SMALLINT UNSIGNED   	PATH '$.SportID'
									,	SubscriberID	INT						PATH '$.SubscriberID'
									,	IsLicenseeVIP	TINYINT					PATH '$.IsLicenseeVIP'
								)) AS tmp;

	IF EXISTS (SELECT 1 FROM Temp_Customer WHERE SportID = 0) THEN
		INSERT INTO Temp_NewCustomerClass(CTSCustID, CustID, SubscriberID, CustomerClass, IsDataChanged, Is4x, Is4xDangerProbation)
		SELECT t.CTSCustID
			,	t.CustID
			,	t.SubscriberID
			,	ip_CustomerClass
			,	CASE WHEN t.IsLicenseeVIP = 1 AND ip_CustomerClass IN (43,45,46,47,2500,2503,2504,2505)  AND clss.CustID IS NULL THEN 0 ELSE 1 END AS  IsDataChanged
			,	CASE WHEN  ip_CustomerClass IN (43,45,46,47,2500,2503,2504,2505) AND clss.CustID IS NOT NULL THEN 1 ELSE 0 END AS  Is4x
			,	CASE WHEN  ip_CustomerClass IN (43,2500) THEN 1 ELSE 0 END AS Is4xDangerProbation
		FROM Temp_Customer AS t
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = t.CustID AND clss.SportGroupID = 100 AND clss.CategoryID = 4
		WHERE t.SportID = 0;
		
		UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_NewCustomerClass AS tmp ON tmp.CustID = clss.CustID AND  clss.SportGroupID = 100 AND  clss.CategoryID  = 4
		SET 	clss.CategoryID = 3
			,	clss.LastModifiedBy = lv_CreatedBy
		WHERE tmp.IsDataChanged = 1;

		/*	INSERT VALID SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
		SELECT 	CTSCustID
			,	CustID
			,	CTSCustID
			,	SubscriberID
			,	CustomerClass
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,   1 -- for Special Customer
		FROM Temp_NewCustomerClass;

		/*	INSERT LOG FOR SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_History(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction, Remark, ActionType)
		SELECT 	CTSCustID
			,	CustID
			,	CTSCustID
			,	SubscriberID
			,	CustomerClass
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,   1 -- for Special Customer
			,	ip_Remark
			,	0 -- insert
		FROM Temp_NewCustomerClass;

		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	19 AS LogTypeID
			,	lv_SPName
			,	CONCAT('Insert SpecialCustomerClass: CTSCustList: ', GROUP_CONCAT(CTSCustID), ';ip_CustomerClass: ', ip_CustomerClass) AS LogInfo
			,	lv_CurrentDateTime
			,	ip_CreatedBy
		FROM Temp_NewCustomerClass;

		/*	INSERT LOG	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History (CustID, CTSCustID, LastModifiedDate, LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT    sp.CustID
				, sp.CTSCustID
				, lv_CurrentDateTime
				, ip_CreatedBy
				, 0  -- insert
				, 0  -- manual
				, DATE(lv_CurrentDateTime)
				, 	CASE 
						WHEN sp.Is4x = 1 AND Is4xDangerProbation = 0 THEN lv_LicVIPCC_Danger
						WHEN sp.Is4x = 1 THEN lv_LicVIPCC_Suspicious
						ELSE sp.CustomerClass 
					END AS CustomerClass
				, 10 -- item name = Add Customer Class
				, 1 -- View History 
				, ip_Remark
		FROM Temp_NewCustomerClass AS sp
		WHERE sp.IsDataChanged = 1;

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, LastModifiedDate, LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT    sp.CustID
				, sp.CTSCustID
				, lv_CurrentDateTime
				, ip_CreatedBy
				, 0  -- insert
				, 0  -- manual
				, DATE(lv_CurrentDateTime)
				, 	CASE 
						WHEN sp.Is4x = 1 AND Is4xDangerProbation = 0 THEN lv_LicVIPCC_Danger
						WHEN sp.Is4x = 1 THEN lv_LicVIPCC_Suspicious
						ELSE sp.CustomerClass 
					END AS CustomerClass
				, 10 -- item name = Add Customer Class
				, 1 -- View History
				, ip_Remark
		FROM Temp_NewCustomerClass AS sp;
		
		/* GET LATEST CC */
		SELECT 	DISTINCT 
				CustId
			,	CustomerClass
			,	-1 AS Category
			,	0 AS SportID
			,	lv_CurrentDateTime AS ScannedTime 
		FROM Temp_NewCustomerClass;
	END IF;

	IF EXISTS (SELECT 1 FROM Temp_Customer WHERE SportID <> 0) THEN
		DELETE tmp
		FROM Temp_NewCustomerClass AS tmp
		WHERE tmp.SportID = 0;

		INSERT INTO Temp_NewCustomerClass(CTSCustID, CustID, SportID, SubscriberID, CustomerClass)
		SELECT	t.CTSCustID
			,	t.CustID
			,	t.SportID
			,	t.SubscriberID
			,	ip_CustomerClass
		FROM Temp_Customer AS t
		WHERE t.SportID <> 0;

		/*	INSERT VALID SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_BySport(CTSCustID, CustID, SportID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate)
		SELECT 	CTSCustID
			,	CustID
			,	SportID
			,	SubscriberID
			,	CustomerClass
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,	ip_CreatedBy
			,	lv_CurrentDateTime
		FROM Temp_NewCustomerClass;

		/*	INSERT LOG FOR SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_BySport_History(CTSCustID, CustID, SportID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, Remark, ActionType)
		SELECT 	CTSCustID
			,	CustID
			,	SportID
			,	SubscriberID
			,	CustomerClass
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,	ip_CreatedBy
			,	lv_CurrentDateTime
			,	ip_Remark
			,	0 -- insert
		FROM Temp_NewCustomerClass;

		SELECT DISTINCT SportID
		INTO lv_SportID
		FROM Temp_NewCustomerClass;

		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	19 AS LogTypeID
			,	lv_SPName
			,	CONCAT('Insert SpecialCustomerClass_BySport: CTSCustList: ', GROUP_CONCAT(CTSCustID),';SportID: ', lv_SportID, ';ip_CustomerClass: ', ip_CustomerClass) AS LogInfo
			,	lv_CurrentDateTime
			,	ip_CreatedBy
		FROM Temp_NewCustomerClass;

		/*	INSERT LOG	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_History (CustID, CTSCustID, SportID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT	CustID
			,	CTSCustID
			,	SportID
			,	lv_CurrentDateTime
			,	ip_CreatedBy
			,	0  -- insert
			,	DATE(lv_CurrentDateTime)
			, 	CustomerClass
			,	ip_Remark
			,	10
		FROM Temp_NewCustomerClass;

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log(CustID, CTSCustID, SportID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT	CustID
			,	CTSCustID
			,	SportID
			,	lv_CurrentDateTime
			,	ip_CreatedBy
			,	0  -- insert
			,	DATE(lv_CurrentDateTime)
			, 	ip_CustomerClass
			,	ip_Remark
			,	10
		FROM Temp_NewCustomerClass;

		/* GET LATEST CC */
		SELECT	CustID
			,	SportID
			,	CustomerClass
		FROM Temp_NewCustomerClass;
	END IF;
END$$
DELIMITER ;