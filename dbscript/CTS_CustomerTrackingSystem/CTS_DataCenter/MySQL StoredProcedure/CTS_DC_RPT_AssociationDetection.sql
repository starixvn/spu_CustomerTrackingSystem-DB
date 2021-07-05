/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_AssociationDetection`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_AssociationDetection`(
		IN ip_CTSCustIDs TEXT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/* 
		Created:	20210629@Casey.Huynh
		Task:		Get Report Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210629@Casey.Huynh: Created [Redmine ID: #157086]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_GetGroupLevel2(200);
	*/
    DECLARE lv_CTSCustID BIGINT UNSIGNED;
    DECLARE lv_GroupID BIGINT UNSIGNED DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS Temp_FromCust;
    CREATE TEMPORARY TABLE Temp_FromCust(
			CTSCustID	BIGINT UNSIGNED
        ,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	Status		VARCHAR(30)		
    );
       
    DROP TEMPORARY TABLE IF EXISTS Temp_ToCust;
    CREATE TEMPORARY TABLE Temp_ToCust(
			CTSCustID	BIGINT UNSIGNED
        ,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	Status		VARCHAR(30)			
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationLevel1;
    CREATE TEMPORARY TABLE Temp_AssociationLevel1(
			FromCTSCustID		BIGINT UNSIGNED
        ,	FromCustID			BIGINT UNSIGNED
        ,	FromCustSubID		BIGINT UNSIGNED
        ,	ToCTSCustID			BIGINT UNSIGNED
        ,	ToCustID			BIGINT UNSIGNED
        ,	ToCustSubID			BIGINT UNSIGNED
		,	LeastCTSCustID 		BIGINT UNSIGNED GENERATED ALWAYS AS (LEAST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        ,	GreatestCTSCustID	BIGINT UNSIGNED GENERATED ALWAYS AS (GREATEST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        
        ,	PRIMARY KEY PK_Temp_AssociationLevel1(LeastCTSCustID,GreatestCTSCustID)
        ,	INDEX IX_Temp_AssociationLevel1_ToCTSCustID(ToCTSCustID)
    );    
    
	    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    CREATE TEMPORARY TABLE Temp_Association(
			FromCTSCustID		BIGINT UNSIGNED
        ,	ToCTSCustID			BIGINT UNSIGNED
        ,	GroupID				BIGINT UNSIGNED    
        ,	LeastCTSCustID 		BIGINT UNSIGNED GENERATED ALWAYS AS (LEAST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        ,	GreatestCTSCustID	BIGINT UNSIGNED GENERATED ALWAYS AS (GREATEST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        
        ,	PRIMARY KEY PK_Temp_AssociationLevel1(LeastCTSCustID,GreatestCTSCustID)
        ,	INDEX 	IX_Temp_AssociationLevel1_GroupID(GroupID)
    );   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice;
    CREATE TEMPORARY TABLE Temp_AssociationByDevice
    (
			CTSCustID	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	DCSDeviceID BIGINT UNSIGNED
        
        ,	PRIMARY KEY Temp_AssociationByDevice(CTSCustID,DCSDeviceID)
    );
    
    #======GET INPUT CUSTOMER======================================================================
    SET @sql = 	CONCAT("INSERT INTO Temp_FromCust(CTSCustID, CustID, CustSubID, UserName, Status)
						SELECT cus.CTSCustID, cus.CustID, cus.CustSubID, cus.UserName, sta.ItemName AS Status
						FROM CTS_DataCenter.CTSCustomer AS cus
							INNER JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cus.CustStatusID
						WHERE cus.CTSCustID IN ('",REPLACE(ip_CTSCustIDs,",","','"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  
    
    INSERT INTO Temp_ToCust(CTSCustID, CustID, CustSubID, UserName, Status)
    SELECT	tmpFc.CTSCustID
		,	tmpFc.CustID
        ,	tmpFc.CustSubID
        ,	tmpFc.UserName
        ,	tmpFc.Status
    FROM Temp_FromCust AS tmpFc;
    
    /*****ASSOCIATION LEVEL 1**************************************************/    
	/*****AssociationByAI******************************************************/
    INSERT INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
    SELECT	tmpFc.CTSCustID AS FromCTSCustID
		,	tmpFc.CustID	AS FromCustID
        ,	tmpFc.CustSubID	AS FromCustSubID
        ,	cus.CTSCustID	AS ToCTSCustID
        ,	cus.CustID		AS ToCustID
        ,	cus.CustSubID	AS ToCustSubID
    FROM CTS_DataCenter.AssociationByAI AS ai
		INNER JOIN Temp_FromCust AS tmpFc ON ai.FromCustID = tmpFc.CustID AND tmpFc.CustSubID = 0
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.ToCustID = cus.CustID AND cus.CustSubID = 0;
   
	INSERT IGNORE INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
    SELECT	tmpTc.CTSCustID AS FromCTSCustID
		,	tmpTc.CustID	AS FromCustID
        ,	tmpTc.CustSubID	AS FromCustSubID
        ,	cus.CTSCustID	AS ToCTSCustID
        ,	cus.CustID		AS ToCustID
        ,	cus.CustSubID	AS ToCustSubID
    FROM CTS_DataCenter.AssociationByAI AS ai
		INNER JOIN Temp_ToCust AS tmpTc ON ai.ToCustID = tmpTc.CustID AND tmpTc.CustSubID = 0
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.FromCustID = cus.CustID AND cus.CustSubID = 0;
	
    /*****AssociationByIP******************************************************/
	INSERT  INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
    SELECT	tmpFc.CTSCustID AS FromCTSCustID
		,	tmpFc.CustID	AS FromCustID
        ,	tmpFc.CustSubID	AS FromCustSubID
        ,	cus.CTSCustID	AS ToCTSCustID
        ,	cus.CustID		AS ToCustID
        ,	cus.CustSubID	AS ToCustSubID
    FROM CTS_DataCenter.AssociationByIP AS ip
		INNER JOIN Temp_FromCust AS tmpFc ON ip.FromCustID = tmpFc.CustID AND tmpFc.CustSubID = 0
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.ToCustID = cus.CustID AND cus.CustSubID = 0;
  
	INSERT IGNORE INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
	SELECT	tmpTc.CTSCustID AS FromCTSCustID
		,	tmpTc.CustID	AS FromCustID
		,	tmpTc.CustSubID	AS FromCustSubID
		,	cus.CTSCustID	AS ToCTSCustID
		,	cus.CustID		AS ToCustID
		,	cus.CustSubID	AS ToCustSubID
	FROM CTS_DataCenter.AssociationByIP AS ip
		INNER JOIN Temp_ToCust AS tmpTc ON ip.ToCustID = tmpTc.CustID AND tmpTc.CustSubID = 0
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.FromCustID = cus.CustID AND cus.CustSubID = 0;

	/*****AssociationByManual**************************************************/
    INSERT IGNORE INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
	SELECT	tmpFc.CTSCustID AS FromCTSCustID
		,	tmpFc.CustID	AS FromCustID
		,	tmpFc.CustSubID	AS FromCustSubID
		,	cus.CTSCustID	AS ToCTSCustID
		,	cus.CustID		AS ToCustID
		,	cus.CustSubID	AS ToCustSubID
	FROM CTS_DataCenter.AssociationByManual AS am
		INNER JOIN Temp_FromCust AS tmpFc ON am.FromCTSCustID = tmpFc.CTSCustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON am.ToCTSCustID = cus.CTSCustID;
		
	INSERT IGNORE INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
	SELECT	tmpTc.CTSCustID AS FromCTSCustID
		,	tmpTc.CustID	AS FromCustID
		,	tmpTc.CustSubID	AS FromCustSubID
		,	cus.CTSCustID	AS ToCTSCustID
		,	cus.CustID		AS ToCustID
		,	cus.CustSubID	AS ToCustSubID
	FROM CTS_DataCenter.AssociationByManual AS am
		INNER JOIN Temp_ToCust AS tmpTc ON am.ToCTSCustID = tmpTc.CTSCustID 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON am.FromCTSCustID = cus.CTSCustID;
		
	/*****AssociationByDevice**************************************************/    
    INSERT INTO Temp_AssociationByDevice(CTSCustID, CustID, CustSubID, DCSDeviceID)
    SELECT	tmpFc.CTSCustID
		,	tmpFc.CustID
        ,	tmpFc.CustSubID
		,	adv.DCSDeviceID
	FROM Temp_FromCust AS tmpFc		
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.CTSCustID = tmpFc.CTSCustID
        INNER JOIN CTS_DataCenter.DeviceAssociationDay AS dsd WHERE dsd.DCSDeviceID = adv.DCSDeviceID;
    
	INSERT IGNORE INTO Temp_AssociationLevel1(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
	SELECT	tmpAd.CTSCustID AS FromCTSCustID
		,	tmpAd.CustID	AS FromCustID
		,	tmpAd.CustSubID	AS FromCustSubID
		,	cus.CTSCustID	AS ToCTSCustID
		,	cus.CustID		AS ToCustID
		,	cus.CustSubID	AS ToCustSubID
	FROM Temp_AssociationByDevice AS tmpAd
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.DCSDeviceID = tmpAd.DCSDeviceID AND adv.CTSCustID <> tmpAd.CTSCustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON adv.CTSCustID = cus.CTSCustID;
        
	/******Insert Association Level 1**********************************************/
	INSERT IGNORE INTO Temp_Association(FromCTSCustID, ToCTSCustID)
	SELECT	FromCTSCustID
        ,	ToCTSCustID
	FROM Temp_AssociationLevel1 AS tmpAl1
	WHERE EXISTS(SELECT 1 FROM Temp_ToCust AS tmpTc WHERE tmpAl1.ToCTSCustID = tmpTc.CTSCustID);
		
	DELETE tmpAl1
	FROM Temp_AssociationLevel1 AS tmpAl1
	WHERE EXISTS(SELECT 1 FROM Temp_ToCust AS tmpTc WHERE tmpAl1.ToCTSCustID = tmpTc.CTSCustID);
    
	 /*****ASSOCIATION LEVEL 2***************************************************/
	 /*****AssociationByAI******************************************************/
	 INSERT IGNORE INTO Temp_Association(FromCTSCustID, ToCTSCustID)
	 SELECT tmpAl1.FromCTSCustID	AS FromCTSCustID
			,	tmpTc.CTSCustID		AS ToCTSCustID
	 FROM Temp_AssociationLevel1 AS tmpAl1
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmpAl1.ToCustID
		INNER JOIN Temp_ToCust AS tmpTc ON ai.ToCustID = tmpTc.CustID AND tmpTc.CustSubID = 0 
	 WHERE tmpAl1.FromCustID <> tmpTc.CustID;

	INSERT IGNORE INTO Temp_Association(FromCTSCustID , ToCTSCustID)
	 SELECT tmpAl1.FromCTSCustID	AS FromCTSCustID
			,	tmpTc.CTSCustID 	AS ToCTSCustID
	 FROM Temp_AssociationLevel1 AS tmpAl1
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmpAl1.ToCustID
		INNER JOIN Temp_ToCust AS tmpTc ON ai.FromCustID = tmpTc.CustID AND tmpTc.CustSubID = 0
	WHERE tmpAl1.FromCustID <> tmpTc.CustID;

	/*****AssociationByIP******************************************************/
	 INSERT IGNORE INTO Temp_Association(FromCTSCustID , ToCTSCustID)
	 SELECT tmpAl1.FromCTSCustID	AS FromCTSCustID
			,	tmpTc.CTSCustID 	AS ToCTSCustID
	 FROM Temp_AssociationLevel1 AS tmpAl1
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmpAl1.ToCustID
		INNER JOIN Temp_ToCust AS tmpTc ON ip.ToCustID = tmpTc.CustID AND tmpTc.CustSubID = 0 
	 WHERE tmpAl1.FromCustID <> tmpTc.CustID;
	
    INSERT IGNORE INTO Temp_Association(FromCTSCustID , ToCTSCustID)
	SELECT tmpAl1.FromCTSCustID		AS FromCTSCustID
		,	tmpTc.CTSCustID			AS ToCTSCustID
	FROM Temp_AssociationLevel1 AS tmpAl1
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmpAl1.ToCustID
		INNER JOIN Temp_ToCust AS tmpTc ON ip.FromCustID = tmpTc.CustID AND tmpTc.CustSubID = 0
	WHERE tmpAl1.FromCustID <> tmpTc.CustID;
    
    /*****AssociationByManual******************************************************/
	INSERT IGNORE INTO Temp_Association(FromCTSCustID , ToCTSCustID)
	SELECT tmpAl1.FromCTSCustID		AS FromCTSCustID
		,	tmpTc.CTSCustID			AS ToCTSCustID
	FROM Temp_AssociationLevel1 AS tmpAl1
		INNER JOIN CTS_DataCenter.AssociationByManual AS am ON am.FromCTSCustID = tmpAl1.ToCTSCustID
		INNER JOIN Temp_ToCust AS tmpTc ON am.ToCTSCustID = tmpTc.CTSCustID
	WHERE tmpAl1.FromCTSCustID <> tmpTc.CTSCustID;
	
	INSERT IGNORE INTO Temp_Association(FromCTSCustID , ToCTSCustID)
	SELECT tmpAl1.FromCTSCustID		AS FromCTSCustID
		,	tmpTc.CTSCustID			AS ToCTSCustID
	FROM Temp_AssociationLevel1 AS tmpAl1
		INNER JOIN CTS_DataCenter.AssociationByManual AS am ON am.ToCTSCustID = tmpAl1.ToCTSCustID
		INNER JOIN Temp_ToCust AS tmpTc ON am.FromCTSCustID = tmpTc.CTSCustID
	WHERE tmpAl1.FromCTSCustID <> tmpTc.CTSCustID;
    
    /*****AssociationByDevice**************************************************/ 
    TRUNCATE TABLE Temp_AssociationByDevice;
    INSERT IGNORE INTO Temp_AssociationByDevice(CTSCustID, CustID, CustSubID, DCSDeviceID)
    SELECT	tmpAl1.FromCTSCustID
		,	tmpAl1.FromCustID
        ,	tmpAl1.FromCustSubID
		,	adv.DCSDeviceID
	FROM Temp_AssociationLevel1 AS tmpAl1		
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.CTSCustID = tmpAl1.FromCTSCustID
        INNER JOIN CTS_DataCenter.DeviceAssociationDay AS dsd WHERE dsd.DCSDeviceID = adv.DCSDeviceID;
    
	INSERT IGNORE INTO Temp_Association(FromCTSCustID , ToCTSCustID)
	SELECT	tmpAd.CTSCustID AS FromCTSCustID
		,	tmpTc.CTSCustID	AS ToCTSCustID
	FROM Temp_AssociationByDevice AS tmpAd
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.DCSDeviceID = tmpAd.DCSDeviceID AND adv.CTSCustID <> tmpAd.CTSCustID
		INNER JOIN Temp_ToCust AS tmpTc ON adv.CTSCustID = tmpTc.CTSCustID;   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustGroup;
    CREATE TEMPORARY TABLE Temp_CustGroup(	
			CTSCustID 	BIGINT UNSIGNED
		,	GroupID		INT
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Association1;
    CREATE TEMPORARY TABLE Temp_Association1 SELECT * FROM Temp_Association;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association2;
    CREATE TEMPORARY TABLE Temp_Association2 SELECT * FROM Temp_Association;
    
    SET lv_CTSCustID = (SELECT FromCTSCustID FROM Temp_Association LIMIT 1);
    
	WHILE (lv_CTSCustID IS NOT NULL)
	DO	
		SET lv_GroupID = lv_GroupID + 1;
        
        INSERT INTO Temp_CustGroup(CTSCustID, GroupID)
		WITH RECURSIVE CTE_CustGroup AS ( 
			SELECT lv_CTSCustID AS CTSCustID
			UNION
			SELECT (CASE WHEN CTE_CustGroup.CTSCustID = ass.FromCTSCustID THEN ass.ToCTSCustID
						 WHEN CTE_CustGroup.CTSCustID = ass.ToCTSCustID THEN ass.FromCTSCustID END)
            FROM Temp_Association  AS ass
				JOIN CTE_CustGroup ON CTE_CustGroup.CTSCustID = ass.FromCTSCustID OR CTE_CustGroup.CTSCustID = ass.ToCTSCustID
		) 
		SELECT CTSCustID, lv_GroupID FROM CTE_CustGroup;
        
        DELETE tmpAss
        FROM Temp_Association AS tmpAss
        WHERE EXISTS (SELECT 1 FROM Temp_CustGroup AS tmpCg WHERE tmpAss.FromCTSCustID = tmpCg.CTSCustID OR tmpAss.ToCTSCustID = tmpCg.CTSCustID);

        #======LOOP CONDITION==================
		SET lv_CTSCustID = (SELECT FromCTSCustID FROM Temp_Association LIMIT 1);        
	END WHILE;
    
    SELECT tmpCg.GroupID
		,	tmpFc.UserName
        ,	tmpFc.Status
		, 	TRIM(GROUP_CONCAT(DISTINCT ' ',evd.EvidenceCode,' ',evd.EvidenceName)) AS Evidence
        , 	TRIM(GROUP_CONCAT(DISTINCT ' ', cat.CategoryName)) AS CustomerCategory
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.CategoryID)) AS CategoryIDs
        ,	tmpFc.CTSCustID
        ,	tmpFc.CustID
        ,	tmpFc.CustSubID
        
    FROM Temp_CustGroup AS tmpCg
		INNER JOIN Temp_FromCust AS tmpFc ON tmpCg.CTSCustID = tmpFc.CTSCustID
		LEFT JOIN CTS_DataCenter.CustEvidence AS ced ON tmpCg.CTSCustID = ced.CTSCustID
        LEFT JOIN CTS_DataCenter.Evidence AS evd ON ced.EvidenceID = evd.EvidenceID
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON tmpFc.CustID = ccl.CustID AND tmpFc.CustSubID = 0
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = ccl.CategoryID
	GROUP BY tmpCg.GroupID, tmpFc.UserName, tmpFc.Status, tmpFc.CTSCustID, tmpFc.CustID, tmpFc.CustSubID;        
   
END$$

DELIMITER ;
