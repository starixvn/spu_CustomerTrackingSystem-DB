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
    DECLARE lv_GroupID 				INT DEFAULT 1;
	DECLARE lv_Count1 				INT;
    DECLARE lv_Count2 				INT;
    DECLARE lv_Count3 				INT;
    DECLARE lv_CTSCustIDs 			JSON;
    DECLARE lv_CTSCustIDAgents 		LONGTEXT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE 		Temp_Group (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
		,	GroupID 			INT
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight,GroupID)
		,	INDEX			    IX_Temp_Group(GroupID)
	);
     
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupProcess;
	CREATE TEMPORARY TABLE 		Temp_GroupProcess (
			CTSCustID 			BIGINT 
		,	Weight 				BIGINT
        ,	Processed			BIT DEFAULT 0
        ,	PRIMARY KEY			PK_Temp_Group(CTSCustID,Weight)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_GroupResult (
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupCustCount;
	CREATE TEMPORARY TABLE 	Temp_GroupCustCount (
			CTSCustID 	INT PRIMARY KEY
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
        ,	Weight
        ,	ParentOrigID
        ,	IsRoot
        ,	AssociationType
    FROM Temp_Graph_Dup;
    
    
    lp: LOOP 
		SET lv_OrigID = NULL;
        SET lv_Weight = NULL;
		SET @crr = CURRENT_TIMESTAMP(3);
        SELECT 	CTSCustID
			,  	TransDateSecond AS Weight
        INTO 	lv_OrigID	
			,	lv_Weight
		FROM Temp_StagingTrans
        WHERE Processed = 0
		LIMIT 1;
	
        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;

        INSERT IGNORE INTO Temp_Group(CTSCustID,Weight,GroupID)
        WITH RECURSIVE CTE_Group AS ( 
				SELECT 	lv_OrigID AS OrigID
					, 	lv_Weight AS Weight
				UNION
                SELECT 	grp.OrigID
					, 	grp.Weight 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID 
										AND (grp.Weight = 0  OR ABS(grp.Weight - lv_Weight) <= ip_Duration)		
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
	
        SELECT COUNT(1)
        INTO lv_Count1
		FROM Temp_Group 
		WHERE GroupID = lv_GroupID;
        
		SELECT COUNT(1)
        INTO lv_Count2
		FROM Temp_StagingTrans AS trans
			INNER JOIN Temp_Group AS grp ON   grp.CTSCustID = trans.CTSCustID AND  grp.Weight = trans.TransDateSecond
		WHERE grp.GroupID = lv_GroupID 
			AND trans.AgentCTSCustID IS NOT NULL
		GROUP BY trans.AgentCTSCustID
		LIMIT 1; 
        
        SELECT COUNT(1)
        INTO lv_Count3
		FROM Temp_Group 
		WHERE GroupID = lv_GroupID
        GROUP BY CTSCustID 
        LIMIT 1; 
        
        IF lv_Count1 IS NOT NULL AND lv_Count1 IN (lv_Count2, lv_Count3) THEN
			DELETE 
            FROM Temp_Group
            WHERE GroupID = lv_GroupID;
        END IF;
        
        SET lv_GroupId = lv_GroupId + 1;
        SET @crr2 = ROUND(TIMESTAMPDIFF(MICROSECOND, CURRENT_TIMESTAMP(3),@crr)/1000);
        SET @lv_AuditInfo = JSON_OBJECT('GroupID', lv_GroupId, 'OrigID', lv_OrigID, 'Weight', lv_Weight, 'Duaration',@crr2);
		INSERT INTO Temp_Monitor(Info) VALUES(@lv_AuditInfo);
     
        SET lv_GroupID = lv_GroupID + 1; 
    END LOOP;
    
    INSERT INTO Temp_GroupCount(GroupID, Total)
    SELECT 	GroupID
		,	COUNT(1)
    FROM Temp_Group
    GROUP BY GroupID
    ORDER BY COUNT(1) DESC;
    
    DELETE 
	FROM Temp_Group AS grp
	WHERE EXISTS (SELECT 1 FROM Temp_GroupCount AS tmp WHERE grp.GroupID = tmp.GroupID AND Total = 1);
  
    /********************************************************************************************/
    
    INSERT INTO Temp_GroupCustCount(CTSCustID)
    SELECT 	CTSCustID
    FROM Temp_Group
    GROUP BY CTSCustID
    HAVING  COUNT(1) > 1;
    
    INSERT IGNORE INTO Temp_GroupProcess(CTSCustID,Weight)
    SELECT 	CTSCustID
		,	Weight
    FROM Temp_Group AS grp
	WHERE EXISTS (SELECT 1 FROM Temp_GroupCustCount AS tmp WHERE tmp.CTSCustID = grp.CTSCustID);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Group_Dup;
	CREATE TEMPORARY TABLE Temp_Group_Dup LIKE Temp_Group;
    INSERT INTO Temp_Group_Dup SELECT * FROM Temp_Group;
    
	INSERT IGNORE INTO Temp_Group(CTSCustID, Weight, GroupID)
	SELECT 	GroupID 
		,	Weight 
        ,	CTSCustID
    FROM Temp_Group_Dup;
    

    
    lp: LOOP 
		SET lv_OrigID = NULL;
        SET lv_Weight = NULL;
        
        SELECT 	CTSCustID
			,  	Weight
        INTO 	lv_OrigID	 
			,	lv_Weight
		FROM Temp_GroupProcess
        WHERE Processed = 0
		LIMIT 1;
        
        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
        
		INSERT IGNORE INTO Temp_GroupResult(CTSCustID,Weight,GroupID)
        WITH RECURSIVE CTE_Group AS ( 
				SELECT 	lv_OrigID AS CTSCustID, lv_Weight AS Weight
				UNION
                SELECT 	grp.CTSCustID, grp.Weight
				FROM Temp_Group  AS grp
					INNER JOIN CTE_Group ON CTE_Group.CTSCustID = grp.GroupID 	
											AND  ABS(grp.Weight -  CTE_Group.Weight) <= ip_Duration				
		) 
		SELECT 	CTSCustID
			,	Weight
			,	lv_GroupId
        FROM CTE_Group AS cte
        WHERE CTSCustID > 0;
        
        SET lv_GroupId = lv_GroupId + 1;
        UPDATE Temp_GroupProcess AS tmp
        SET tmp.Processed = 1
        WHERE  (tmp.CTSCustID = lv_OrigID AND tmp.Weight = lv_Weight)
			OR EXISTS (SELECT 1 FROM Temp_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID AND gp.Weight = tmp.Weight);

    END LOOP;
    
    INSERT IGNORE INTO Temp_GroupResult(CTSCustID, Weight, GroupID)
	SELECT 	CTSCustID  
		,	Weight 
        ,	GroupID
    FROM Temp_Group_Dup;

    UPDATE Temp_StagingTrans AS tran
		INNER JOIN Temp_GroupResult AS tmp ON tran.CTSCustID = tmp.CTSCustID AND tmp.Weight = tran.TransDateSecond
    SET tran.GroupID = tmp.GroupID;
    
END$$
DELIMITER ;
