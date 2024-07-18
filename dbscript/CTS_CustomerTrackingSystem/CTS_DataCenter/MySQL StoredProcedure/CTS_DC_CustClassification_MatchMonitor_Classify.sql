/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_MatchMonitor_Classify`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_MatchMonitor_Classify`(
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220627@Casey.Huynh	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20220627@Casey.Huynh: Created [Redmine ID: #174218]
            - 20220908@Casey.Huynh: New CC for Classify MM [Redmine ID: #176976]
            - 20220113@Casey.Huynh: Rename Table [Redmine ID: #179502]
            - 20231120@Thomas.Nguyen: Add the condition SportType = 2 and include Odds Crawler Robot (CategoryID 165, 166), Abnormal Account - Robot (CategoryID 179) [Redmine ID: #188553]
			- 20240319@Casey.Huynh: Classify Danger Score [Redmine ID: #201358]
            - 20240425@Thomas.Nguyen: Classify Initial Group Betting - Remove GroupPriority [Redmine ID: #200854]    
			- 20240530@Casey.Huynh:	Saba Group Betting (NOT Classify Saba GB Match) [Redmine ID: #191972]
			- 20240717@Jonas.Huynh:	Renovate CC [Redmine ID: #205317]
            
		Param's Explanation:
        
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Classify();
	 */
        
	DECLARE	CONST_PARENTID_PA						INT;
    
	DECLARE	CONST_CATEID_ROBOTUSER					INT;
	DECLARE	CONST_CATEID_ROBOTUSERLOSING			INT;
	DECLARE	CONST_CATEID_ROBOTOCRD					INT;
	DECLARE	CONST_CATEID_ROBOTOCRDLOSING			INT;
	DECLARE	CONST_CATEID_ROBOTUSERABNORMALACCOUNT	INT;
	DECLARE	CONST_CATEID_ROBOTBETTING				INT;
	DECLARE	CONST_CATEID_SYSTEMDETECTGB				INT;
    
  	DECLARE	CONST_CATEGROUPID_SYSTEMDETECTGB		INT;
    
	DECLARE lv_PackSize INT;
	DECLARE lv_MatchID INT;
     
    SET CONST_PARENTID_PA	 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
    SET CONST_CATEID_ROBOTBETTING	 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTBETTING');
	SET CONST_CATEID_ROBOTOLD	 			    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOLD');
    SET CONST_CATEID_ROBOTUSER	 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSER');
    SET CONST_CATEID_ROBOTUSERLOSING			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSERLOSING');
    SET CONST_CATEID_ROBOTOCRD	 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRD');
    SET CONST_CATEID_ROBOTOCRDLOSING			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRDLOSING');
    SET CONST_CATEID_ROBOTUSERABNORMAL	        = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSERABNORMAL');
    SET CONST_CATEID_SYSTEMDETECTGB	 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SYSTEMDETECTGB');
    
    SET CONST_CATEGROUPID_SYSTEMDETECTGB 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SYSTEMDETECTGB');

    
    /*****GET SYSTEM Parameter VALUE****/
    SELECT s.ParameterValue
    INTO lv_PackSize
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = 95;
    
    SELECT s.ParameterValue
    INTO lv_MatchID
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = 96;
   
    IF lv_MatchID = 0 THEN    
		SELECT mm.MatchID
        INTO lv_MatchID
        FROM CTS_DataCenter.MatchMonitor AS mm
        WHERE mm.ClassifyStatus = 2	AND SportType IN (1,2) 
			AND mm.LeagueGroupID IS NULL
        ORDER BY mm.KickOffTime ASC
        LIMIT 1;
        
        UPDATE CTS_DataCenter.SystemParameter AS s
        SET s.ParameterValue = lv_MatchID
        WHERE s.ParameterID = 96;        
	END IF;
 
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorDetailsCust;
    CREATE TEMPORARY TABLE Temp_MatchMonitorDetailsCust(
			CustID			INT UNSIGNED
		,	MMDetailsID		INT
        ,	Reason			TINYINT
		,	MatchID			INT		      
        ,	NoOfCust		INT
        
        ,	INDEX IX_Temp_MatchMonitorDetailsCust(CustID, MMDetailsID)
    );
   
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID			INT UNSIGNED
		,	MMDetailsID		INT  
		,	MatchID			INT		      
        ,	CTSCustID		BIGINT UNSIGNED
        ,	RoleID			TINYINT
        ,	SubscriberID	INT UNSIGNED
        ,	IsLicensee		TINYINT(1)
        
        ,	PRIMARY KEY PK_Temp_Cust(CustID, MMDetailsID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExcludePACategoryID;
    CREATE TEMPORARY TABLE Temp_ExcludePACategoryID(
    
			CategoryID		INT UNSIGNED	       
        ,	PRIMARY KEY PK_Temp_ExcludePA(CategoryID)
    );

	INSERT INTO Temp_ExcludePACategoryID(CategoryID)
    SELECT cat.CategoryID
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.ParentID = CONST_PARENTID_PA AND cat.CategoryID NOT IN (CONST_CATEID_ROBOTBETTING, CONST_CATEID_ROBOTOLD, CONST_CATEID_ROBOTUSER, CONST_CATEID_ROBOTUSERLOSING, CONST_CATEID_ROBOTOCRD, CONST_CATEID_ROBOTOCRDLOSING, CONST_CATEID_ROBOTUSERABNORMAL);

    INSERT INTO Temp_MatchMonitorDetailsCust(CustID, MMDetailsID, MatchID, NoOfCust)
    WITH CTE_MatchMonitorDetials AS
    ( 	SELECT	mmd.ID AS MMDetailsID
			,	mmd.HighStakeLicCustList
            ,	mmd.MatchID
		FROM CTS_DataCenter.MatchMonitorDetails AS mmd
        WHERE mmd.MatchID = lv_MatchID
			AND mmd.Reason = 0
			AND mmd.ClassifyStatus = 0
        LIMIT lv_PackSize
	)
	SELECT	js.CustID
		,	cte.MMDetailsID
        ,	cte.MatchID
        ,	LENGTH(cte.HighStakeLicCustList) - LENGTH(REPLACE(cte.HighStakeLicCustList,',','')) + 1 AS NoOfCust
	FROM CTE_MatchMonitorDetials AS cte
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(cte.HighStakeLicCustList), ',', '","'), 
						'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
						) js;    

    INSERT INTO Temp_Cust(CustID, MMDetailsID, MatchID, CTSCustID, RoleID, SubscriberID, IsLicensee)
    SELECT	tmpMmc.CustID
		,	tmpMmc.MMDetailsID
        ,	tmpMmc.MatchID
        ,	cus.CTSCustID
        ,	cus.RoleID
        ,	cus.SubscriberID
        ,	cus.IsLicensee
    FROM Temp_MatchMonitorDetailsCust AS tmpMmc
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpMmc.CustID = cus.CustID
	WHERE tmpMmc.CustID IS NOT NULL;

    SELECT	DISTINCT tmpCust.CustID
        ,	tmpCust.MatchID
        ,	tmpCust.CTSCustID
        ,	tmpCust.RoleID
        ,	tmpCust.SubscriberID
        ,	tmpCust.IsLicensee
        ,	CONST_CATEID_SYSTEMDETECTGB AS CategoryID # Group Betting
        , 	CONST_CATEGROUPID_SYSTEMDETECTGB AS CategoryGroup # Group Betting
	FROM Temp_Cust AS tmpCust
	WHERE NOT EXISTS (	SELECT 1 
						FROM CTS_DataCenter.CTSCustomerClassification AS cls 
							INNER JOIN Temp_ExcludePACategoryID AS exl ON cls.CategoryID = exl.CategoryID
						WHERE cls.CustID = tmpCust.CustID);
        
    SELECT GROUP_CONCAT(DISTINCT MmDetailsID) AS MmDetailsIDList
    FROM Temp_MatchMonitorDetailsCust AS tmp;
    
    SELECT lv_MatchID AS MatchID;
END$$
DELIMITER ;