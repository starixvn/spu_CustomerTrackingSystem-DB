/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_DetectGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_DetectGroup`(
		IN 	ip_Duration	INT UNSIGNED
	,	IN	ip_IsLog	BOOLEAN
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
            -   20221107@Aries.Nguyen: Tuning performance of Hedging Detection  [Redmine ID: #180185]
            - 	20221205@Aries.Nguyen: Re-arrange type options on Association Detection  [Redmine ID: #181207]
            -	20230612@Casey.Huynh: LogInfo [RedmineID: #185793]
            -	20240627@Casey.Huynh:	EuroCup Exclude AssociationByIP [RedmineID: #207117]
            -	20240716@Casey.Huynh:	After EuroCup, Rollback AssociationByIP [RedmineID: #207117]

		Param's Explanation (filtered by):
			- 	Temp_StagingTrans tbl: CustID,CTSCustID,TransDateSecond,AgentCTSCustID,Processed,GroupID
		Example:
			-	CALL CTS_DC_MatchMonitor_DetectGroup(180);
	*/
    DECLARE lv_OrigID 				BIGINT;
	DECLARE lv_Weight 				BIGINT ;
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
        ,	OldGroupID 			INT
        ,	IsOld				BIT DEFAULT 0
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupPrecessed;
	CREATE TEMPORARY TABLE 		Temp_GroupPrecessed (
			Weight 				BIGINT
		,	GroupID 			BIGINT
        ,	PRIMARY KEY			PK_Temp_Group(GroupID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupPrepare;
	CREATE TEMPORARY TABLE 		Temp_GroupPrepare (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
		,	GroupID 			BIGINT
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupCTSCustID;
	CREATE TEMPORARY TABLE 		Temp_GroupCTSCustID (
			CTSCustID 			BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupParentPrepare;
	CREATE TEMPORARY TABLE 		Temp_GroupParentPrepare (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
		,	GroupID 			BIGINT
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
			GroupID 			BIGINT PRIMARY KEY	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Parent;
	CREATE TEMPORARY TABLE Temp_Parent(
			AgentCTSCustID		BIGINT 
		 ,	CTSCustID			BIGINT 
		 ,	TransDateSecond		BIGINT 
         ,	OldGroupID			BIGINT 
		 , 	Processed			BIT DEFAULT 0
		 ,	PRIMARY KEY 		PK_Temp_StagingTrans(AgentCTSCustID, TransDateSecond)
		 ,	INDEX 				IX_Temp_StagingTrans_AgentCTSCustID(CTSCustID)
	 );	

     /*****************Handle Trans processed***********/
     INSERT IGNORE INTO Temp_GroupResult(CTSCustID,AgentCTSCustID,Weight,GroupID,OldGroupID,IsOld)
     SELECT CTSCustID
		,	AgentCTSCustID
		,	TransDateSecond
		,	OldGroupID AS GroupID
        ,	OldGroupID AS OldGroupID
        ,	1 AS IsOld
     FROM Temp_StagingTrans 
     WHERE OldGroupID IS NOT NULL
        AND OldGroupID != 0;
     
     SELECT MAX(GroupID)
     INTO lv_GroupID
     FROM Temp_GroupResult;
     
     IF lv_GroupID IS NULL OR lv_GroupID <= 0  THEN
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
	WITH CTE AS (
		SELECT 	DISTINCT
				CTSCustID
			,	CustID
        FROM Temp_StagingTrans
    )
    SELECT JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', CustID)) AS CustJson
	INTO lv_CTSCustIDs	
    FROM CTE;

    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetEdge(lv_CTSCustIDs,1,1,1);

    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, AssociationType)
	SELECT	grp.CTSCustID 
		,	(-1*grp.OldGroupID) 
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.OldGroupID;
    
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, AssociationType)
	SELECT	(-1*grp.OldGroupID) 
		,	grp.CTSCustID
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.OldGroupID;
	
    #=====LOG185793: START====================================================
    IF (ip_IsLog = 1) THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_LogAsscust;
		CREATE TEMPORARY TABLE Temp_LogAsscust(
				CTSCustID BIGINT UNSIGNED
			,	CustID	BIGINT UNSIGNED
			,	GroupID	INT
			,	PRIMARY KEY (CTSCustID, GroupID)
		);
    END IF;
    #=====LOG185793: END====================================================
    
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

        INSERT IGNORE INTO Temp_GroupCTSCustID(CTSCustID)
        WITH RECURSIVE CTE_Group AS ( 
				SELECT 	lv_OrigID AS OrigID
				UNION
                SELECT 	grp.OrigID
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID	
		) 
		SELECT OrigID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_StagingTrans AS tmp WHERE tmp.CTSCustID = cte.OrigID);
        
        INSERT IGNORE INTO Temp_GroupPrepare(CTSCustID,Weight,GroupID)
        SELECT 	trans.CTSCustID
			,	trans.TransDateSecond
            ,	lv_GroupID AS GroupID
        FROM Temp_GroupCTSCustID  AS tmp 
			INNER JOIN Temp_StagingTrans  AS trans  ON trans.CTSCustID = tmp.CTSCustID 
            LEFT JOIN Temp_GroupPrecessed AS grp ON trans.OldGroupID = grp.GroupID
		WHERE ABS(lv_Weight - trans.TransDateSecond) <= ip_Duration	
			OR ABS(lv_Weight - IFNULL(grp.Weight,0)) <= ip_Duration;          
												
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
        
        INSERT IGNORE Temp_GroupResult(CTSCustID, Weight, GroupID)
        SELECT 	CTSCustID
			,	Weight
            ,	GroupID
        FROM Temp_GroupPrepare;
        
		#=====LOG185793: START====================================================
		IF (ip_IsLog = 1) THEN
			INSERT IGNORE INTO Temp_LogAsscust(CTSCustID, CustID, GroupID)
			SELECT 	tmp.CTSCustID
				, 	tmpTs.CustID
                ,	lv_GroupID
			FROM Temp_GroupCTSCustID AS tmp
                INNER JOIN Temp_StagingTrans  AS tmpTs  ON tmpTs.CTSCustID = tmp.CTSCustID ;
        END IF;
		#=====LOG185793: END====================================================
        
        UPDATE Temp_StagingTrans AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID AND gp.Weight = tmp.TransDateSecond);
         
        SET lv_GroupID = lv_GroupID + 1; 
        TRUNCATE TABLE Temp_GroupCTSCustID;
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
	
    WITH CTE AS (
		SELECT 	DISTINCT 
				AgentCTSCustID AS CTSCustID
        FROM Temp_Parent
    )
    SELECT JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', NULL)) AS CustJson
	INTO lv_CTSCustIDs	
    FROM CTE;
    
	CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetEdge(lv_CTSCustIDs,1,0,0);
    
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, AssociationType)
	SELECT	grp.AgentCTSCustID 
		,	(-1*grp.OldGroupID) 
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.OldGroupID
	WHERE grp.IsOld = 1 
		AND grp.AgentCTSCustID IS NOT NULL;
    
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, AssociationType)
	SELECT	(-1*grp.OldGroupID) 
		,	grp.AgentCTSCustID
        ,	-1 AS AssociationType
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_GroupPrecessed AS tmp ON tmp.GroupID = grp.OldGroupID
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
 
        INSERT IGNORE INTO Temp_GroupCTSCustID(CTSCustID) 
        WITH RECURSIVE CTE_Group AS ( 
				SELECT 	lv_OrigID AS OrigID
				UNION
                SELECT 	grp.OrigID
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID 
		) 
		SELECT OrigID AS CTSCustID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_Parent AS tmp WHERE tmp.AgentCTSCustID = cte.OrigID);
        
		#=====LOG185793: START===========================================================
        IF (ip_IsLog = 1) THEN
			INSERT IGNORE INTO Temp_LogAsscust(CTSCustID, CustID, GroupID)
			SELECT 	tmpTs.CTSCustID
				,	tmpTs.CustID
				, 	lv_GroupID
			FROM Temp_GroupCTSCustID AS tmp
				INNER JOIN Temp_Parent  AS trans  ON trans.AgentCTSCustID = tmp.CTSCustID
                INNER JOIN Temp_StagingTrans  AS tmpTs  ON tmpTs.CTSCustID = trans.CTSCustID ;
		END IF;
		#=====LOG185793: END=============================================================
	
        INSERT IGNORE INTO Temp_GroupParentPrepare(CTSCustID,Weight,GroupID)
        SELECT 	trans.AgentCTSCustID
			,	trans.TransDateSecond
            ,	lv_GroupID AS GroupID
        FROM Temp_GroupCTSCustID  AS tmp 
			INNER JOIN Temp_Parent  AS trans  ON trans.AgentCTSCustID = tmp.CTSCustID
            LEFT JOIN Temp_GroupPrecessed AS grp ON trans.OldGroupID = grp.GroupID
		WHERE ABS(lv_Weight - trans.TransDateSecond) <= ip_Duration
			OR  ABS(lv_Weight - IFNULL(grp.Weight,0)) <= ip_Duration;
		
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
        
        TRUNCATE TABLE Temp_GroupCTSCustID;
        TRUNCATE TABLE Temp_GroupParentPrepare;
        TRUNCATE TABLE Temp_ParentCust;
        TRUNCATE TABLE Temp_GroupID;
    END LOOP;

    UPDATE Temp_StagingTrans AS tran
		INNER JOIN Temp_GroupResult AS tmp ON tran.CTSCustID = tmp.CTSCustID AND tmp.Weight = tran.TransDateSecond
    SET tran.GroupID = tmp.GroupID;
    
END$$
DELIMITER ;
