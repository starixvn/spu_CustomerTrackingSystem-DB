/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetGroup2LevelToTemp_CustGroup2L_checkPer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetGroup2LevelToTemp_CustGroup2L_checkPer`(
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustGroup2L;
    CREATE TEMPORARY TABLE Temp_CustGroup2L(	
			CTSCustID 	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	CustStatus	VARCHAR(50)	
		,	GroupID		INT
	);    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustGroup;
    CREATE TEMPORARY TABLE Temp_CustGroup(	
			CTSCustID 	BIGINT UNSIGNED
		,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	CustStatus	VARCHAR(50)	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FromCust;
    CREATE TEMPORARY TABLE Temp_FromCust(
			CTSCustID	BIGINT UNSIGNED
        ,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	CustStatus		VARCHAR(30)	
        
        ,	PRIMARY KEY PK_Temp_FromCust(CTSCustID)
        ,	INDEX IX_Temp_FromCust_CTSCustID(CustID,CustSubID)
        
    );
       
    DROP TEMPORARY TABLE IF EXISTS Temp_ToCust;
    CREATE TEMPORARY TABLE Temp_ToCust(
			CTSCustID	BIGINT UNSIGNED
        ,	CustID		BIGINT UNSIGNED
        ,	CustSubID	BIGINT UNSIGNED
        ,	UserName	VARCHAR(50)
        ,	CustStatus		VARCHAR(30)
        
        ,	PRIMARY KEY PK_Temp_ToCust(CTSCustID)
        ,	INDEX IX_Temp_ToCust_CTSCustID(CustID,CustSubID)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByCustID;
    CREATE TEMPORARY TABLE Temp_AssociationByCustID(
			FromCTSCustID		BIGINT UNSIGNED
        ,	FromCustID			BIGINT UNSIGNED
        ,	FromCustSubID		BIGINT UNSIGNED
        ,	ToCustID			BIGINT UNSIGNED
		,	LeastCustID 		BIGINT UNSIGNED GENERATED ALWAYS AS (LEAST(FromCustID,ToCustID)) STORED NOT NULL
        ,	GreatestCustID		BIGINT UNSIGNED GENERATED ALWAYS AS (GREATEST(FromCustID,ToCustID)) STORED NOT NULL
        
        ,	PRIMARY KEY PK_Temp_AssociationAll(LeastCustID,GreatestCustID)
        ,	INDEX IX_Temp_AssociationAll_ToCustID(ToCustID)
        ,	INDEX IX_Temp_AssociationAll_FromCustID(FromCustID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByCTSCustID;
    CREATE TEMPORARY TABLE Temp_AssociationByCTSCustID(
			FromCTSCustID		BIGINT UNSIGNED
        ,	FromCustID			BIGINT UNSIGNED
        ,	FromCustSubID		BIGINT UNSIGNED
        ,	ToCTSCustID			BIGINT UNSIGNED
		,	LeastCTSCustID 		BIGINT UNSIGNED GENERATED ALWAYS AS (LEAST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        ,	GreatestCTSCustID	BIGINT UNSIGNED GENERATED ALWAYS AS (GREATEST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        
        ,	PRIMARY KEY PK_Temp_AssociationAll(LeastCTSCustID,GreatestCTSCustID)
        ,	INDEX IX_Temp_AssociationAll_ToCTSCustID(ToCTSCustID)
        ,	INDEX IX_Temp_AssociationAll_FromCTSCustID(FromCTSCustID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationAll;
    CREATE TEMPORARY TABLE Temp_AssociationAll(
			FromCTSCustID		BIGINT UNSIGNED
        ,	FromCustID			BIGINT UNSIGNED
        ,	FromCustSubID		BIGINT UNSIGNED
        ,	ToCTSCustID			BIGINT UNSIGNED
        ,	ToCustID			BIGINT UNSIGNED
        ,	ToCustSubID			BIGINT UNSIGNED
		,	LeastCTSCustID 		BIGINT UNSIGNED GENERATED ALWAYS AS (LEAST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        ,	GreatestCTSCustID	BIGINT UNSIGNED GENERATED ALWAYS AS (GREATEST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        
        ,	PRIMARY KEY PK_Temp_AssociationAll(LeastCTSCustID,GreatestCTSCustID)
        ,	INDEX IX_Temp_AssociationAll_ToCTSCustID(ToCTSCustID)
        ,	INDEX IX_Temp_AssociationAll_FromCTSCustID(FromCTSCustID)
    );        
	    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssGroup2Level;
    CREATE TEMPORARY TABLE Temp_AssGroup2Level(
			FromCTSCustID		BIGINT UNSIGNED
        ,	ToCTSCustID			BIGINT UNSIGNED
        ,	GroupID				BIGINT UNSIGNED    
        ,	LeastCTSCustID 		BIGINT UNSIGNED GENERATED ALWAYS AS (LEAST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        ,	GreatestCTSCustID	BIGINT UNSIGNED GENERATED ALWAYS AS (GREATEST(FromCTSCustID,ToCTSCustID)) STORED NOT NULL
        
        ,	PRIMARY KEY PK_Temp_AssociationAll(LeastCTSCustID,GreatestCTSCustID)
        ,	INDEX 	IX_Temp_AssociationAll_GroupID(GroupID)
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
    
    /**DEBUG**/
    SET @Step=0;
	TRUNCATE TABLE CTS_Adhoc.PerformanceCheck;
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'1');
     /**DEBUG**/
     
    #======GET INPUT CUSTOMER======================================================================
    SET @sql = 	CONCAT("INSERT INTO Temp_FromCust(CTSCustID, CustID, CustSubID, UserName, CustStatus)
						SELECT cus.CTSCustID, cus.CustID, cus.CustSubID, cus.UserName, sta.ItemName AS CustStatus
						FROM CTS_DataCenter.CTSCustomer AS cus
							INNER JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cus.CustStatusID
						WHERE cus.CTSCustID IN ('",REPLACE(ip_CTSCustIDs,",","','"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  
    
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'2');
     /**DEBUG**/
     
    INSERT INTO Temp_ToCust(CTSCustID, CustID, CustSubID, UserName, CustStatus)
    SELECT	tmpFc.CTSCustID
		,	tmpFc.CustID
        ,	tmpFc.CustSubID
        ,	tmpFc.UserName
        ,	tmpFc.CustStatus
    FROM Temp_FromCust AS tmpFc;
    
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'3');
     /**DEBUG**/
    
    /*****ASSOCIATION LEVEL 1**************************************************/    
	/*****AssociationByAI******************************************************/
    INSERT INTO Temp_AssociationByCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCustID)
    SELECT	tmpFc.CTSCustID AS FromCTSCustID
		,	tmpFc.CustID	AS FromCustID
        ,	tmpFc.CustSubID	AS FromCustSubID
        ,	ai.ToCustID		AS ToCustID
    FROM Temp_FromCust AS tmpFc 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmpFc.CustID AND tmpFc.CustSubID = 0;
    
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'4');
     /**DEBUG**/
    
	INSERT IGNORE INTO Temp_AssociationByCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCustID)
    SELECT	tmpTc.CTSCustID AS FromCTSCustID
		,	tmpTc.CustID	AS FromCustID
        ,	tmpTc.CustSubID	AS FromCustSubID
        ,	ai.FromCustID		AS ToCustID
    FROM Temp_ToCust AS tmpTc 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmpTc.CustID AND tmpTc.CustSubID = 0;
	
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'5');
     /**DEBUG**/
    
    /*****AssociationByIP******************************************************/
	INSERT IGNORE INTO Temp_AssociationByCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCustID)
    SELECT	tmpFc.CTSCustID AS FromCTSCustID
		,	tmpFc.CustID	AS FromCustID
        ,	tmpFc.CustSubID	AS FromCustSubID
        ,	ip.ToCustID		AS ToCustID
    FROM Temp_FromCust AS tmpFc 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmpFc.CustID AND tmpFc.CustSubID = 0;
    
	
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'6');
     /**DEBUG**/
    
	INSERT IGNORE INTO Temp_AssociationByCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCustID)
	SELECT	tmpTc.CTSCustID AS FromCTSCustID
		,	tmpTc.CustID	AS FromCustID
		,	tmpTc.CustSubID	AS FromCustSubID
		,	ip.FromCustID		AS ToCustID
	FROM Temp_ToCust AS tmpTc 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmpTc.CustID AND tmpTc.CustSubID = 0;
	
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'7');
     /**DEBUG**/
    
	/*****AssociationByManual**************************************************/
    INSERT IGNORE INTO Temp_AssociationByCTSCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID)
	SELECT	tmpFc.CTSCustID AS FromCTSCustID
		,	tmpFc.CustID	AS FromCustID
		,	tmpFc.CustSubID	AS FromCustSubID
		,	am.ToCTSCustID	AS ToCTSCustID
	FROM CTS_DataCenter.AssociationByManual AS am
		INNER JOIN Temp_FromCust AS tmpFc ON am.FromCTSCustID = tmpFc.CTSCustID;
	
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'8');
     /**DEBUG**/
    
	INSERT IGNORE INTO Temp_AssociationByCTSCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID)
	SELECT	tmpTc.CTSCustID 	AS FromCTSCustID
		,	tmpTc.CustID		AS FromCustID
		,	tmpTc.CustSubID		AS FromCustSubID
		,	am.FromCTSCustID	AS ToCTSCustID
	FROM Temp_ToCust AS tmpTc 
		INNER JOIN CTS_DataCenter.AssociationByManual AS am ON am.ToCTSCustID = tmpTc.CTSCustID;
	
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'9');
     /**DEBUG**/
    	
	/*****AssociationByDevice**************************************************/    
    INSERT IGNORE INTO Temp_AssociationByDevice(CTSCustID, CustID, CustSubID, DCSDeviceID)
    SELECT	tmpFc.CTSCustID
		,	tmpFc.CustID
        ,	tmpFc.CustSubID
		,	adv.DCSDeviceID
	FROM Temp_FromCust AS tmpFc		
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.CTSCustID = tmpFc.CTSCustID
        INNER JOIN CTS_DataCenter.DeviceAssociationDay AS dsd WHERE dsd.DCSDeviceID = adv.DCSDeviceID;
    
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'10');
     /**DEBUG**/
    
	INSERT IGNORE INTO Temp_AssociationByCTSCustID(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID)
	SELECT	tmpAd.CTSCustID AS FromCTSCustID
		,	tmpAd.CustID	AS FromCustID
		,	tmpAd.CustSubID	AS FromCustSubID
		,	adv.CTSCustID	AS ToCTSCustID
	FROM Temp_AssociationByDevice AS tmpAd
		INNER JOIN CTS_DataCenter.AssociationByDevice AS adv ON adv.DCSDeviceID = tmpAd.DCSDeviceID AND adv.CTSCustID <> tmpAd.CTSCustID;
     
    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'11');
     /**DEBUG**/
    /**********************************************************************/
    INSERT IGNORE INTO Temp_AssociationAll(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
	SELECT	tmpAss.FromCTSCustID 	AS FromCTSCustID
		,	tmpAss.FromCustID		AS FromCustID
		,	tmpAss.FromCustSubID	AS FromCustSubID
		,	cus.CTSCustID			AS ToCTSCustID
        ,	cus.CustID				AS ToCustID
        ,	cus.CustSubID			AS ToCustSubID
    FROM Temp_AssociationByCTSCustID AS tmpAss
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpAss.ToCTSCustID = cus.CTSCustID;
	
    INSERT IGNORE INTO Temp_AssociationAll(FromCTSCustID, FromCustID, FromCustSubID, ToCTSCustID, ToCustID, ToCustSubID)
	SELECT	tmpAss.FromCTSCustID 	AS FromCTSCustID
		,	tmpAss.FromCustID		AS FromCustID
		,	tmpAss.FromCustSubID	AS FromCustSubID
		,	cus.CTSCustID			AS ToCTSCustID
        ,	cus.CustID				AS ToCustID
        ,	cus.CustSubID			AS ToCustSubID
    FROM Temp_AssociationByCustID AS tmpAss
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpAss.ToCustID = cus.CustID AND cus.CustSubID = 0;
	
    SET lv_CTSCustID = (SELECT FromCTSCustID FROM Temp_AssociationAll LIMIT 1);
   
	WHILE (lv_CTSCustID IS NOT NULL)
	DO	
		
        TRUNCATE TABLE Temp_CustGroup;
        INSERT INTO Temp_CustGroup(CTSCustID, CustID, CustSubID, UserName, CustStatus)
		WITH RECURSIVE CTE_CustGroup AS ( 
			SELECT lv_CTSCustID AS CTSCustID
			UNION
			SELECT (CASE WHEN CTE_CustGroup.CTSCustID = ass.FromCTSCustID THEN ass.ToCTSCustID
						 WHEN CTE_CustGroup.CTSCustID = ass.ToCTSCustID THEN ass.FromCTSCustID END)
            FROM Temp_AssociationAll AS ass
				JOIN CTE_CustGroup ON CTE_CustGroup.CTSCustID = ass.FromCTSCustID OR CTE_CustGroup.CTSCustID = ass.ToCTSCustID
		) 
		SELECT	cte.CTSCustID
			,	tmpFc.CustID
            ,	tmpFc.CustSubID
            ,	tmpFc.UserName
            ,	tmpFc.CustStatus
        FROM CTE_CustGroup AS cte
			INNER JOIN Temp_FromCust AS tmpFc ON tmpFc.CTSCustID = cte.CTSCustID;
        
        IF (SELECT COUNT(1) FROM (SELECT 1 FROM Temp_CustGroup LIMIT 2) AS tmp) > 1
        THEN
			SET lv_GroupID = lv_GroupID + 1;
            INSERT INTO Temp_CustGroup2L(CTSCustID, CustID, CustSubID, UserName, CustStatus, GroupID)
            SELECT	tmpCg.CTSCustID
				,	tmpCg.CustID
				,	tmpCg.CustSubID
				,	tmpCg.UserName
				,	tmpCg.CustStatus
                ,	lv_GroupID
			FROM	Temp_CustGroup AS tmpCg;
        END IF;
        
        DELETE tmpAss
        FROM Temp_AssociationAll AS tmpAss
        WHERE EXISTS (SELECT 1 FROM Temp_CustGroup AS tmpCg WHERE tmpAss.FromCTSCustID = tmpCg.CTSCustID OR tmpAss.ToCTSCustID = tmpCg.CTSCustID);

        #======LOOP CONDITION==================
		SET lv_CTSCustID = (SELECT FromCTSCustID FROM Temp_AssociationAll LIMIT 1);        
	END WHILE;

    /**DEBUG**/
    insert into CTS_Adhoc.PerformanceCheck(Step, StartTime, Comments)
    Values(@Step:=@Step+1,CURRENT_TIMESTAMP(3),'21');
     /**DEBUG**/
    
    
END$$

DELIMITER ;
