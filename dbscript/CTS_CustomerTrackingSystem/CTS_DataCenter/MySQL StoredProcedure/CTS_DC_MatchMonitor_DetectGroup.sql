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
            
		Param's Explanation (filtered by):
			- 	Temp_StagingTrans tbl: CustID,CTSCustID,TransDateSecond,AgentCTSCustID,Processed,GroupID
		Example:
			-	CALL CTS_DC_MatchMonitor_DetectGroup(180);
	*/
    
    DECLARE CONS_Range1 			BIGINT DEFAULT 10000000000;
	DECLARE CONS_Range2 			BIGINT DEFAULT 20000000000;
    DECLARE CONS_Range3 			BIGINT DEFAULT 30000000000;
    DECLARE CONS_Range4 			BIGINT DEFAULT 40000000000;
    DECLARE CONS_Range5 			BIGINT DEFAULT 50000000000;
    DECLARE CONS_Range6 			BIGINT DEFAULT 60000000000;
    
    DECLARE lv_OrigID 				BIGINT;
	DECLARE lv_Weight 				BIGINT;
    DECLARE lv_ParentOrigID			BIGINT;
    DECLARE lv_GroupID 				INT DEFAULT 1;
    DECLARE lv_CTSCustIDs 			LONGTEXT;
    DECLARE lv_CTSCustIDAgents 		LONGTEXT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GraphRoot;
	CREATE TEMPORARY TABLE 	Temp_GraphRoot (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
        ,	AssociationType   	SMALLINT
		,	PRIMARY KEY(OrigID, DestID, AssociationType)
		,	INDEX IX_Temp_GraphRoot(DestID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE 		Temp_Group (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
		,	GroupID 			INT
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupCount;
	CREATE TEMPORARY TABLE 	Temp_GroupCount (
			ID  		INT AUTO_INCREMENT PRIMARY KEY
		,	GroupID 	INT
        ,	Total 		INT
		,	UNIQUE 	    IX_Temp_GroupCount(GroupID)
	);
    
    SELECT GROUP_CONCAT(DISTINCT CTSCustID)
    INTO lv_CTSCustIDs
    FROM Temp_StagingTrans;
    
    SELECT GROUP_CONCAT(DISTINCT AgentCTSCustID)
    INTO lv_CTSCustIDAgents
    FROM Temp_StagingTrans  
	WHERE AgentCTSCustID IS NOT NULL;
    
    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetNode(lv_CTSCustIDs,1,1,1,1,"Temp_Graph",0,0,CONS_Range1,CONS_Range2);
    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetNode(lv_CTSCustIDAgents,1,1,0,0,"Temp_GraphAgent",CONS_Range3,CONS_Range3,CONS_Range5,CONS_Range6);

    INSERT IGNORE INTO Temp_GraphRoot(OrigID, DestID, AssociationType)
    SELECT 	grp.OrigID
		, 	grp.DestID
        ,	grp.AssociationType
	FROM Temp_Graph AS grp
		INNER JOIN Temp_StagingTrans AS tran ON tran.CTSCustID = grp.OrigID;
   
    DELETE 
    FROM Temp_Graph AS grp
    WHERE EXISTS (SELECT 1 FROM Temp_GraphRoot AS tmp WHERE grp.OrigID = tmp.OrigID);
	
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight, ParentOrigID, IsRoot,  AssociationType)
    SELECT 	tmp.OrigID
		, 	tmp.DestID
        , 	tran.TransDateSecond AS Weight
        ,	NULL AS ParentOrigID
        ,	1 AS IsRoot
        , 	tmp.AssociationType
	FROM Temp_GraphRoot AS tmp
		INNER JOIN Temp_StagingTrans AS tran ON tran.CTSCustID = tmp.OrigID;
   
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight,ParentOrigID, IsRoot, AssociationType)
    SELECT 	tmp.OrigID
		, 	tmp.DestID
        , 	tmp.Weight
        ,	NULL AS ParentOrigID
        ,	0 AS IsRoot
        , 	tmp.AssociationType
	FROM Temp_GraphAgent AS tmp;
	
    INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight,ParentOrigID, IsRoot, AssociationType)
    SELECT 	tran.CTSCustID AS OrigID
		, 	(tran.AgentCTSCustID + CONS_Range3) AS DestID
        , 	tran.TransDateSecond AS Weight
        ,	(tran.AgentCTSCustID + CONS_Range3) AS ParentOrigID
        ,	1 AS IsRoot
        , 	6
	FROM Temp_StagingTrans AS tran
		WHERE tran.AgentCTSCustID IS NOT NULL;
        
	DROP TEMPORARY TABLE IF EXISTS Temp_Graph_Dup;
	CREATE TEMPORARY TABLE Temp_Graph_Dup LIKE Temp_Graph;
    INSERT INTO Temp_Graph_Dup SELECT * FROM Temp_Graph;
    
	INSERT IGNORE INTO Temp_Graph(OrigID, DestID, Weight,ParentOrigID, IsRoot, AssociationType)
	SELECT 	DestID 
		,	OrigID
        ,	0 AS Weight
        ,	NULL AS ParentOrigID
        ,	0 AS IsRoot
        ,	AssociationType
    FROM Temp_Graph_Dup;
    
    lp: LOOP 
		SET lv_OrigID = NULL;
        SET lv_Weight = NULL;
        SET lv_ParentOrigID = NULL;

        SELECT 	CTSCustID
			,  	TransDateSecond AS Weight
            ,	(AgentCTSCustID+ CONS_Range3) AS ParentOrigID
        INTO 	lv_OrigID	
			,	lv_Weight
            ,	lv_ParentOrigID
		FROM Temp_StagingTrans
        WHERE Processed = 0
		LIMIT 1;

        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
        
        INSERT IGNORE INTO Temp_Group(CTSCustID,Weight,GroupID)
        WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID, lv_Weight AS Weight, lv_ParentOrigID AS ParentOrigID
				UNION
				SELECT grp.OrigID,  CASE WHEN grp.Weight = 0 THEN CTE_Group.Weight ELSE grp.Weight END AS Weight, grp.ParentOrigID
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID 
										AND (grp.Weight = 0  OR ABS(grp.Weight - CAST(CTE_Group.Weight AS SIGNED)) <= ip_Duration)
                                        AND (grp.ParentOrigID IS NULL 
												OR CTE_Group.ParentOrigID IS NULL 
												OR (CTE_Group.ParentOrigID = grp.ParentOrigID AND grp.IsRoot = 0) 
                                                OR (CTE_Group.ParentOrigID != grp.ParentOrigID AND grp.IsRoot = 1))
		) 
		SELECT OrigID
			,  Weight
            ,  lv_GroupID AS GroupID
        FROM CTE_Group;
                         
        UPDATE Temp_StagingTrans AS tmp
        SET tmp.Processed = 1
        WHERE  (tmp.CTSCustID = lv_OrigID AND tmp.TransDateSecond = lv_Weight)
			OR EXISTS (SELECT 1 FROM Temp_Group AS gp WHERE  gp.CTSCustID = tmp.CTSCustID AND gp.Weight = tmp.TransDateSecond);
            
		SET lv_GroupId = lv_GroupId + 1;
	END LOOP;
    
	DELETE 
	FROM Temp_Group AS grp
	WHERE NOT EXISTS (SELECT 1 FROM Temp_StagingTrans AS tmp WHERE grp.CTSCustID = tmp.CTSCustID);
   
    INSERT INTO Temp_GroupCount(GroupID, Total)
    SELECT 	GroupID
		,	COUNT(1)
    FROM Temp_Group
    GROUP BY GroupID
    ORDER BY COUNT(1) DESC;
    
    DELETE 
	FROM Temp_Group AS grp
	WHERE EXISTS (SELECT 1 FROM Temp_GroupCount AS tmp WHERE grp.GroupID = tmp.GroupID AND Total = 1);
    
    UPDATE Temp_StagingTrans AS tran
		INNER JOIN Temp_Group AS tmp ON tran.CTSCustID = tmp.CTSCustID AND tmp.Weight = tran.TransDateSecond
    SET tran.GroupID = tmp.GroupID;
    
END$$
DELIMITER ;
