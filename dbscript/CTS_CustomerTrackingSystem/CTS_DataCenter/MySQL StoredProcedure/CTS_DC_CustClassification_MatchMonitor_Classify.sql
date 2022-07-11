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
            
		Param's Explanation:
        
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Classify();
            CALL CTS_DataCenter.CTS_DC_CustClassification_MatchMonitor_Completed(50604006,NULL);
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
        WHERE mm.ClassifyStatus = 2	AND SportType = 1 # Match Completed (EventStatus = Completed AND NOT Existing IN MatchMonitorStagingLive)
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
        
        ,	PRIMARY KEY PK_Temp_MatchMonitorDetailsCust(CustID, MMDetailsID)
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
    
    INSERT INTO Temp_MatchMonitorDetailsCust(CustID, MMDetailsID, MatchID, NoOfCust)
    WITH CTE_MatchMonitorDetials AS
    ( 	SELECT	mmd.ID AS MMDetailsID
			,	mmd.ListCustID
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
        ,	LENGTH(cte.ListCustID) - LENGTH(REPLACE(cte.ListCustID,',','')) + 1 AS NoOfCust
	FROM CTE_MatchMonitorDetials AS cte
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(cte.ListCustID), ',', '","'), 
						'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
						) js;    
    
    INSERT INTO Temp_Cust(CustID, MMDetailsID, MatchID, CTSCustID, RoleID, SubscriberID, IsLicensee)
    SELECT tmpMmc.CustID
		, tmpMmc.MMDetailsID
        , tmpMmc.MatchID
        , cus.CTSCustID
        , cus.RoleID
        , cus.SubscriberID
        , cus.IsLicensee
    FROM Temp_MatchMonitorDetailsCust AS tmpMmc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpMmc.CustID = cus.CustID
	WHERE	tmpMmc.NoOfCust > 2
			AND cus.IsLicensee = 1;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_PACustGroup;
    CREATE TEMPORARY TABLE Temp_PACustGroup(MmDetailsID INT);
    
    INSERT INTO Temp_PACustGroup(MmDetailsID)
    SELECT tmpCus.MmDetailsID
    FROM Temp_Cust AS tmpCus
    GROUP BY tmpCus.MmDetailsID
    HAVING COUNT(1) > 2;
    
    SELECT	DISTINCT tmpCust.CustID
        ,	tmpCust.MatchID
        ,	tmpCust.CTSCustID
        ,	tmpCust.RoleID
        ,	tmpCust.SubscriberID
        ,	tmpCust.IsLicensee
        ,	52 AS CategoryID # Group Betting
        , 	52 AS CategoryGroup # Group Betting
	FROM Temp_Cust AS tmpCust
		INNER JOIN Temp_PACustGroup AS tmpPa ON tmpCust.MMDetailsID = tmpPa.MMDetailsID;
        
    SELECT GROUP_CONCAT(DISTINCT MmDetailsID) AS MmDetailsIDList
    FROM Temp_MatchMonitorDetailsCust AS tmp;
    
    SELECT lv_MatchID AS MatchID;
END$$
DELIMITER ;