/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_LicVIP_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_LicVIP_Insert`(
		IN ip_CustJson  TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
		/*
		Created:	20200705@Casey.Huynh
		Task :		New Category Licensee VIP 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200705@Casey.Huynh [Redmine ID: #174219]: Created
            
		Param's Explanation:
            
		Example:
			CALL CTS_DC_CustClassification_LicVIP_Insert('[{"CustID":"791050", "CreatedBy": 12345}, {"CustID":"12345", "CreatedBy": 835067}]');
	*/    
    
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CustomerClass	INT;
    DECLARE lv_ActionType		INT DEFAULT 0;
	DECLARE lv_IsAuto			INT DEFAULT 0;
    DECLARE lv_VIPPriority		SMALLINT;
    
	DECLARE	CONST_GROUP_WRAPER				INT DEFAULT 100;
    DECLARE CONST_CATEGORY_VIPPROBLEM 		INT DEFAULT 3;
    DECLARE CONST_CATEGORY_VIPNORMAL 		INT DEFAULT 4;
    DECLARE CONST_CC_VIPPROBLEM 			INT DEFAULT 99;
    DECLARE CONST_CC_VIPNORMAL 				INT DEFAULT 100;
    DECLARE CONST_SOURCETYPEID 				INT DEFAULT 38;

	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE 		Temp_Customer (
		 	/*Cust info*/
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED
        , 	SubscriberID			INT 
        ,	CreatedBy 				INT UNSIGNED
        , 	IsLicenseeVIP				INT 
         
         ,	PRIMARY KEY PK_Temp_Customer(CustID)
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
	CREATE TEMPORARY TABLE 		Temp_CustCategory (
		 	/*Cust info*/
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED
        , 	SubscriberID			INT 
        ,	CreatedBy 				INT UNSIGNED
         ,	CategoryID				INT
         ,	IsDangerProbation		TINYINT(1)
         ,	Priority				SMALLINT 
         ,	CustomerClass			SMALLINT UNSIGNED
         ,	IsDataChanged			TINYINT(1) DEFAULT 0
         , 	IsLicenseeVIP				INT 
         ,	PRIMARY KEY PK_Temp_Customer(CustID)
	);    

    #=======================================================================================
    SELECT cat.Priority
    INTO lv_VIPPriority
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.CategoryID IN (CONST_CATEGORY_VIPPROBLEM,CONST_CATEGORY_VIPNORMAL)
    LIMIT 1;
    
    #=======================================================================================
    INSERT INTO Temp_Customer(CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP) 
	SELECT 	DISTINCT tmpJs.CustID, cus.CTSCustID, cus.SubscriberID, tmpJs.CreatedBy, (CASE WHEN cls.CustID IS NULL THEN 0 ELSE 1 END) AS IsLicenseeVIP
	FROM JSON_TABLE(ip_CustJson,
		 "$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED		PATH "$.CustID"
            ,	CreatedBy 		BIGINT UNSIGNED		PATH "$.CreatedBy"
		 )) AS tmpJs
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON  tmpJs.CustID = cus.CustID AND cus.CustSubID = 0
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON  tmpJs.CustID = cls.CustID  AND CategoryID IN (CONST_CATEGORY_VIPPROBLEM,CONST_CATEGORY_VIPNORMAL) ;    

	 INSERT INTO Temp_CustCategory(CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP, CategoryID, IsDangerProbation, Priority, CustomerClass ) 
     WITH CTE_LastCategory AS
     (
		 SELECT	tmpCus.CustID
			,	tmpCus.CTSCustID
			,	tmpCus.SubscriberID
			,	tmpCus.CreatedBy
            ,	tmpCus.IsLicenseeVIP
			,	tmpLastCat.CategoryID
            ,	tmpLastCat.Priority
            ,	tmpLastCat.IsDangerProbation
            ,	tmpLastCat.CustomerClass
            
		 FROM Temp_Customer AS tmpCus,
		 LATERAL (
			SELECT cls.CategoryID, cat.Priority, cat.IsDangerProbation, cat.CustomerClass 
			FROM CTS_DataCenter.CTSCustomerClassification AS cls
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = cls.CategoryID AND cat.Priority < lv_VIPPriority
			WHERE cls.CustID = tmpCus.CustID
			ORDER BY cls.CustID, cls.LastModifiedDate DESC
			LIMIT 1
		 ) AS tmpLastCat
     ) 
     SELECT cte.CustID
		,	cte.CTSCustID
        ,	cte.SubscriberID
        ,	cte.CreatedBy
        ,	cte.IsLicenseeVIP
        ,	cte.CategoryID
        ,	cte.IsDangerProbation
        ,	cte.Priority
        ,	cte.CustomerClass
     FROM  CTE_LastCategory AS cte;    
     
    #======NOT Update CC if Priority Value of Current Less than VIP.Priority ===========================================
    UPDATE Temp_CustCategory AS tmpCus
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = tmpCus.CustID
    SET tmpCus.Priority = -1;	
    
    UPDATE Temp_CustCategory AS tmpCus
    SET tmpCus.IsDataChanged = 1
        , tmpCus.CustomerClass = (CASE WHEN tmpCus.IsDangerProbation = 1 THEN CONST_CC_VIPNORMAL ELSE CONST_CC_VIPPROBLEM END)
    WHERE tmpCus.IsLicenseeVIP != 1 AND ( tmpCus.Priority IS NULL OR tmpCus.Priority > lv_VIPPriority); # Change CC
    
    #=======================================================================================
    UPDATE CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN Temp_Customer AS tmpCus ON cus.CTSCustID = tmpCus.CTSCustID
	SET cus.IsLicenseeVIP = 1
		, cus.ModifiedTime = lv_CurrentDateTime
    WHERE cus.IsLicenseeVIP <> 1;   
    
    #=======================================================================================
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CTSCustID, CustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsDirect) 
	SELECT	tmpCus.CTSCustID
		,	tmpCus.CustID
		,	tmpCus.SubscriberID
		,	CONST_GROUP_WRAPER
		,	(CASE WHEN tmpCus.IsDangerProbation = 1 THEN CONST_CATEGORY_VIPNORMAL ELSE CONST_CATEGORY_VIPPROBLEM END) AS CategoryID #
		,	lv_CurrentDateTime AS CreatedDate
		,	tmpCus.CreatedBy
		,	lv_CurrentDateTime AS LastModifiedDate
		,	tmpCus.CreatedBy AS LastModifiedBy
		,	DATE(lv_CurrentDateTime) LastScannedDate
        ,	1 AS IsDirect
	FROM Temp_CustCategory AS tmpCus;
    
	/*Insert VVIP history*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID , LastModifiedDate, LastModifiedBy, ActionType
			, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsDirect)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	(CASE WHEN tmpCus.IsDangerProbation = 1 THEN CONST_CATEGORY_VIPNORMAL ELSE CONST_CATEGORY_VIPPROBLEM END) AS CategoryID #
		, 	CONST_GROUP_WRAPER
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpCus.CreatedBy AS LastModifiedBy
		,	lv_ActionType
		,	lv_IsAuto
		,   DATE(lv_CurrentDateTime) AS InsertDate
		,   tmpCus.CustomerClass AS TargetCC
		,   CONST_SOURCETYPEID AS SourceTypeID
		,	1 AS IsDataChanged
        ,	1 AS IsDirect
	FROM Temp_CustCategory AS tmpCus
    WHERE  tmpCus.IsDataChanged = 1;

	INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsDirect)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	(CASE WHEN tmpCus.IsDangerProbation = 1 THEN CONST_CATEGORY_VIPNORMAL ELSE CONST_CATEGORY_VIPPROBLEM END) AS CategoryID #
		, 	CONST_GROUP_WRAPER
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpCus.CreatedBy AS LastModifiedBy
		,	lv_ActionType
		,	lv_IsAuto
		,   DATE(lv_CurrentDateTime) AS InsertDate
		,   tmpCus.CustomerClass AS TargetCC
		,   CONST_SOURCETYPEID AS SourceTypeID
		,	tmpCus.IsDataChanged
        ,	1 AS IsDirect
    FROM Temp_CustCategory AS tmpCus;
  
	SELECT	tmpCus.CustID
    FROM Temp_CustCategory AS tmpCus
    WHERE tmpCus.IsDataChanged = 1;
END$$
DELIMITER ;