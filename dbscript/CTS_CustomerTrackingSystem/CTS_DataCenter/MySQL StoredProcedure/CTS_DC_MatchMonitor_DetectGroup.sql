/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_DetectGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_DetectGroup`(
		IN 	ip_Duration  INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221006@Aries.Nguyen
		Task :		Get Match Monitor report
		DB:			CTS_DataCenter
		Original:
 
		Revisions:
			- 	20221006@Aries.Nguyen: Created [Redmine ID: 178310]
            -   20221025@Aries.Nguyen: Tuning performance: Skip the processed trans  [Redmine ID: #179439]

		Param's Explanation (filtered by):
			- 	Temp_StagingTrans tbl: CustID,CTSCustID,TransDateSecond,AgentCTSCustID,Processed,GroupID
		Example:
			-	CALL CTS_DC_MatchMonitor_DetectGroup(180);
	*/
    DECLARE lv_OrigID 				BIGINT;
	DECLARE lv_Weight 				BIGINT;
    DECLARE lv_GroupID 				INT DEFAULT 1;
	DECLARE lv_Count1 				INT;
    DECLARE lv_Count2 				INT;
    DECLARE lv_CTSCustIDs 			JSON;

    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_GroupResult (
			CTSCustID 			BIGINT 
		,	AgentCTSCustID		BIGINT
		,	Weight 				BIGINT
		,	GroupID 			INT
        ,	IsOld				BIT DEFAULT 0
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupPrecessed;
	CREATE TEMPORARY TABLE 		Temp_GroupPrecessed (
			Weight 				BIGINT
		,	GroupID 			INT
        ,	PRIMARY KEY			PK_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupPrepare;
	CREATE TEMPORARY TABLE 		Temp_GroupPrepare (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
		,	GroupID 			INT
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupParentPrepare;
	CREATE TEMPORARY TABLE 		Temp_GroupParentPrepare (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
		,	GroupID 			INT
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ParentCust;
	CREATE TEMPORARY TABLE 		Temp_ParentCust (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupID;
	CREATE TEMPORARY TABLE 		Temp_GroupID (
			GroupID 			INT PRIMARY KEY	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Parent;
	CREATE TEMPORARY TABLE Temp_Parent(
			AgentCTSCustID		BIGINT UNSIGNED
		 ,	CTSCustID			BIGINT UNSIGNED
		 ,	TransDateSecond		BIGINT UNSIGNED
         ,	OldGroupID			INT 
		 , 	Processed			BIT DEFAULT 0
		 ,	PRIMARY KEY 		PK_Temp_StagingTrans(AgentCTSCustID, TransDateSecond)
		 ,	INDEX 				IX_Temp_StagingTrans_AgentCTSCustID(CTSCustID)
	 );	

     /*****************Handle Trans processed***********/
     INSERT IGNORE INTO Temp_GroupResult(CTSCustID,AgentCTSCustID,Weight,GroupID,IsOld)
     SELECT CTSCustID
		,	AgentCTSCustID
		,	TransDateSecond
		,	OldGroupID
        ,	1 AS IsOld
     FROM Temp_StagingTrans 
     WHERE OldGroupID IS NOT NULL
        AND OldGroupID != 0;
     
     SELECT MAX(GroupID)
     INTO lv_GroupID
     FROM Temp_GroupResult;
     
     IF lv_GroupID IS NULL THEN
		SET lv_GroupID = 1;
	ELSE
		SET lv_GroupID = lv_GroupID + 1;
	END IF;
    
    INSERT INTO Temp_GroupPrecessed(GroupID,Weight)
    SELECT 	GroupID
		,	MAX(Weight)
    FROM Temp_GroupResult
    GROUP BY GroupID;
       
     
     /******************************************Detect group******************************************/
    SELECT	JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', trans.CTSCustID ,'CustID', trans.CustID ,'Weight', trans.TransDateSecond,'MaxWeight', tmp.Weight )) AS CustJson
	INTO lv_CTSCustIDs
    FROM Temp_StagingTrans AS trans
		LEFT JOIN Temp_GroupPrecessed AS tmp ON trans.OldGroupID = tmp.GroupID;  

    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetNode(lv_CTSCustIDs,1,1,1,1);

    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight, MaxWeight, AssociationType)
	SELECT	grp.CTSCustID 
		,	(-1*grp.GroupID) 
        ,	grp.Weight
        ,	tmp.Weight AS MaxWeight
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.GroupID;
    
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight, MaxWeight, AssociationType)
	SELECT	(-1*grp.GroupID) 
		,	grp.CTSCustID
        ,	grp.Weight
        ,	tmp.Weight AS MaxWeight
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.GroupID;

    lp: LOOP 
		SET lv_OrigID = NULL;
        SET lv_Weight = NULL;

        SELECT 	CTSCustID
			,  	TransDateSecond AS Weight
        INTO 	lv_OrigID	
			,	lv_Weight
		FROM Temp_StagingTrans
        WHERE Processed = 0
		LIMIT 1;
        
        UPDATE Temp_StagingTrans AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID 
			AND tmp.TransDateSecond = lv_Weight;
        
        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;

        INSERT IGNORE INTO Temp_GroupPrepare(CTSCustID,Weight,GroupID)
        WITH RECURSIVE CTE_Group AS ( 
				SELECT 	lv_OrigID AS OrigID
					, 	lv_Weight AS Weight
				UNION
                SELECT 	grp.OrigID
					, 	grp.Weight 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID 
										AND (grp.Weight = 0  
												OR ABS(grp.Weight - lv_Weight) <= ip_Duration
                                                OR ABS(grp.MaxWeight - lv_Weight) <= ip_Duration)		
		) 
		SELECT OrigID
			,  Weight
            ,  lv_GroupID AS GroupID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_StagingTrans AS tmp WHERE tmp.CTSCustID = cte.OrigID AND tmp.TransDateSecond = cte.Weight);
        
        SELECT 	COUNT(1)
			,	COUNT(DISTINCT CTSCustID)
        INTO 	lv_Count1
			,	lv_Count2
        FROM Temp_GroupPrepare;
        
        IF lv_Count1 = 1 OR lv_Count2 = 1 THEN
			TRUNCATE TABLE Temp_GroupPrepare;
        END IF;
        
        INSERT IGNORE INTO Temp_GroupID(GroupID)
        SELECT 	DISTINCT 
				gr.GroupID
        FROM Temp_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_GroupPrepare AS tmp WHERE gr.CTSCustID = tmp.CTSCustID AND gr.Weight = tmp.Weight);
        
        IF EXISTS (SELECT 1 FROM Temp_GroupID) THEN
			UPDATE Temp_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_GroupID AS tmp WHERE gr.GroupID = tmp.GroupID);
        END IF;
        
        INSERT IGNORE Temp_GroupResult(CTSCustID,Weight,GroupID)
        SELECT 	CTSCustID
			,	Weight
            ,	GroupID
        FROM Temp_GroupPrepare;
        
        UPDATE Temp_StagingTrans AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID AND gp.Weight = tmp.TransDateSecond);
         
        SET lv_GroupID = lv_GroupID + 1; 
        TRUNCATE TABLE Temp_GroupPrepare;
        TRUNCATE TABLE Temp_GroupID;
    END LOOP;
    
	/******************************************Detect group by agent******************************************/
    INSERT IGNORE INTO Temp_Parent(AgentCTSCustID,CTSCustID,TransDateSecond,OldGroupID)
     SELECT AgentCTSCustID
		, 	CTSCustID
        , 	TransDateSecond
        ,	OldGroupID
     FROM Temp_StagingTrans
     WHERE AgentCTSCustID IS NOT NULL;
	
    SELECT	JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', trans.AgentCTSCustID ,'CustID', NULL ,'Weight', trans.TransDateSecond,'MaxWeight', tmp.Weight )) AS CustJson
	INTO lv_CTSCustIDs
    FROM Temp_Parent AS trans
		LEFT JOIN Temp_GroupPrecessed AS tmp ON trans.OldGroupID = tmp.GroupID;  
    
	CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetNode(lv_CTSCustIDs,1,1,0,0);
    
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight, MaxWeight, AssociationType)
	SELECT	grp.AgentCTSCustID 
		,	(-1*grp.GroupID) 
        ,	grp.Weight
        ,	tmp.Weight AS MaxWeight
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.GroupID
	WHERE grp.IsOld = 1 
		AND grp.AgentCTSCustID IS NOT NULL;
    
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight, MaxWeight, AssociationType)
	SELECT	(-1*grp.GroupID) 
		,	grp.AgentCTSCustID
        ,	grp.Weight
        ,	tmp.Weight AS MaxWeight
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.GroupID
	WHERE grp.IsOld = 1 
		AND grp.AgentCTSCustID IS NOT NULL;

    lp: LOOP 
		SET lv_OrigID = NULL;
        SET lv_Weight = NULL;

        SELECT 	AgentCTSCustID
			,  	TransDateSecond AS Weight
        INTO 	lv_OrigID	
			,	lv_Weight
		FROM Temp_Parent
        WHERE Processed = 0
		LIMIT 1;
        
        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;

        INSERT IGNORE INTO Temp_GroupParentPrepare(CTSCustID,Weight,GroupID)
        WITH RECURSIVE CTE_Group AS ( 
				SELECT 	lv_OrigID AS OrigID
					, 	lv_Weight AS Weight
				UNION
                SELECT 	grp.OrigID
					, 	grp.Weight 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID 
										AND (grp.Weight = 0  
												OR ABS(grp.Weight - lv_Weight) <= ip_Duration		
												OR ABS(grp.MaxWeight - lv_Weight) <= ip_Duration)
		) 
		SELECT OrigID
			,  Weight
            ,  lv_GroupID AS GroupID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_Parent AS tmp WHERE tmp.AgentCTSCustID = cte.OrigID AND tmp.TransDateSecond = cte.Weight);

        UPDATE Temp_Parent AS tmp
        SET tmp.Processed = 1
        WHERE  (tmp.AgentCTSCustID = lv_OrigID AND tmp.TransDateSecond = lv_Weight)
			OR EXISTS (SELECT 1 FROM Temp_GroupParentPrepare AS gp WHERE  gp.CTSCustID = tmp.AgentCTSCustID AND gp.Weight = tmp.TransDateSecond);

        SELECT 	COUNT(1)
			,	COUNT(DISTINCT CTSCustID)
        INTO 	lv_Count1
			,	lv_Count2
        FROM Temp_GroupParentPrepare;
        
        IF lv_Count1 = 1 OR lv_Count2 = 1 THEN
			TRUNCATE TABLE Temp_GroupParentPrepare;
        END IF;
       
        INSERT IGNORE INTO Temp_ParentCust(CTSCustID,Weight)
        SELECT 	tran.CTSCustID
			,	tran.TransDateSecond
        FROM Temp_StagingTrans AS tran
        WHERE EXISTS (SELECT 1 FROM Temp_GroupParentPrepare AS tmp WHERE tmp.CTSCustID = tran.AgentCTSCustID AND tmp.Weight = tran.TransDateSecond);

        INSERT IGNORE INTO Temp_GroupID(GroupID)
        SELECT 	DISTINCT 
				gr.GroupID
        FROM Temp_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_ParentCust AS tmp WHERE gr.CTSCustID = tmp.CTSCustID AND gr.Weight = tmp.Weight);
        
        IF EXISTS (SELECT 1 FROM Temp_GroupID) THEN
			UPDATE Temp_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_GroupID AS tmp WHERE gr.GroupID = tmp.GroupID);
        END IF;
        
        INSERT IGNORE Temp_GroupResult(CTSCustID,Weight,GroupID)
        SELECT 	CTSCustID
			,	Weight
            ,	lv_GroupID
        FROM Temp_ParentCust;
        
        SET lv_GroupID = lv_GroupID + 1; 
        TRUNCATE TABLE Temp_GroupParentPrepare;
        TRUNCATE TABLE Temp_ParentCust;
        TRUNCATE TABLE Temp_GroupID;
    END LOOP;

    UPDATE Temp_StagingTrans AS tran
		INNER JOIN Temp_GroupResult AS tmp ON tran.CTSCustID = tmp.CTSCustID AND tmp.Weight = tran.TransDateSecond
    SET tran.GroupID = tmp.GroupID;
    
END$$
DELIMITER ;
