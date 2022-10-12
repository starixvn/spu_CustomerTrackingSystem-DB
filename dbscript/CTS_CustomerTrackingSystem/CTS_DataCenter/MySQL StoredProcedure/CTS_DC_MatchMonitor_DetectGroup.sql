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
    
    DECLARE CONS_Range 			BIGINT DEFAULT 30000000000;

    DECLARE lv_OrigID 				BIGINT;
	DECLARE lv_Weight 				BIGINT;
    DECLARE lv_ParentOrigID			BIGINT;
    DECLARE lv_GroupID 				INT DEFAULT 1;
    DECLARE lv_CTSCustIDs 			JSON;
    DECLARE lv_CTSCustIDAgents 		LONGTEXT;
    
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Monitor;
	CREATE TEMPORARY TABLE 	Temp_Monitor (
			ID  		BIGINT AUTO_INCREMENT PRIMARY KEY
		,	Info 		JSON
	);
    
    SELECT	JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', CustID ,'Weight', TransDateSecond,'ParentOrigID', 0 )) AS CustJson
	INTO lv_CTSCustIDs
    FROM Temp_StagingTrans;  
    
	SELECT	JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', CustID ,'Weight', TransDateSecond, 'ParentOrigID', AgentCTSCustID)) AS CustJson 
    INTO lv_CTSCustIDAgents
    FROM Temp_StagingTrans  
	WHERE AgentCTSCustID IS NOT NULL;

    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetNode(lv_CTSCustIDs,lv_CTSCustIDAgents,1,1,1,1);
  
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
		SET @crr = CURRENT_TIMESTAMP(3);
		SET lv_OrigID = NULL;
        SET lv_Weight = NULL;
        SET lv_ParentOrigID = NULL;

        SELECT 	CTSCustID
			,  	TransDateSecond AS Weight
            ,	(AgentCTSCustID+ CONS_Range) AS ParentOrigID
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
				SELECT grp.OrigID,  CASE WHEN grp.Weight = 0 THEN CTE_Group.Weight ELSE grp.Weight END AS Weight, IFNULL(grp.ParentOrigID, CTE_Group.ParentOrigID)
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID 
										AND (grp.Weight = 0  OR ABS(grp.Weight - CAST(CTE_Group.Weight AS SIGNED)) <= ip_Duration)
                                        AND (grp.ParentOrigID IS NULL 
												OR CTE_Group.ParentOrigID IS NULL 
												OR (CTE_Group.ParentOrigID = grp.ParentOrigID AND grp.IsRoot = 0) 
                                                OR (CTE_Group.ParentOrigID != grp.ParentOrigID AND grp.IsRoot = 1))
				LIMIT 1000000
		) 
		SELECT OrigID
			,  Weight
            ,  lv_GroupID AS GroupID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_StagingTrans AS tmp WHERE tmp.CTSCustID = cte.OrigID AND tmp.TransDateSecond = cte.Weight);
                         
        UPDATE Temp_StagingTrans AS tmp
        SET tmp.Processed = 1
        WHERE  (tmp.CTSCustID = lv_OrigID AND tmp.TransDateSecond = lv_Weight)
			OR EXISTS (SELECT 1 FROM Temp_Group AS gp WHERE  gp.CTSCustID = tmp.CTSCustID AND gp.Weight = tmp.TransDateSecond);
		

		SET lv_GroupId = lv_GroupId + 1;
        SET @crr2 = ROUND(TIMESTAMPDIFF(MICROSECOND, CURRENT_TIMESTAMP(3),@crr)/1000);
        SET @lv_AuditInfo = JSON_OBJECT('GroupID', lv_GroupId, 'OrigID', lv_OrigID, 'Weight', lv_Weight, 'ParentOrigID', lv_ParentOrigID, 'Duaration',@crr2);
		INSERT INTO Temp_Monitor(Info) VALUES(@lv_AuditInfo);
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
