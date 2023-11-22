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
            - 20231120@Thomas.Nguyen: Add the condition SportType = 2 and include Odds Crawler Robot (CategoryID 165, 166) [Redmine ID: #188553]

		Param's Explanation:
        
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Classify();
	 */ 
	DECLARE lv_PackSize INT;
	DECLARE lv_MatchID INT;
    
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
    SELECT CategoryID
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE ParentID = 50 AND CategoryID NOT IN  (57,61,163,164,165,166);   

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
        ,	63 AS CategoryID # Group Betting
        , 	63 AS CategoryGroup # Group Betting
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