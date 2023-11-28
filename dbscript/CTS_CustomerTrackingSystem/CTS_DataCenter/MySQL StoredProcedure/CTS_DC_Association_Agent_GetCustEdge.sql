/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_Association_Agent_GetCustEdge`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Agent_GetCustEdge`(
		IN	ip_CTSCustIDs 		LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN 
	/*  
		Created:	20231117@Victoria.Le
		Task:		Enhance Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20231117@Victoria.Le: Initial Writing - Renovate Association Detection [Redmine ID: #192172]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_Agent_GetCustEdge('1,2,3');
	*/
	DECLARE lv_GroupID 				BIGINT DEFAULT 1;
	DECLARE lv_AgentJson	 		JSON;
	DECLARE lv_OrigID 				BIGINT;
	DECLARE lv_Count 				INT;
	
	#=============================================================================	
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 	Temp_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
        ,	Recommend			BIGINT
		,	INDEX 				Temp_Cust(CustID)
        ,	INDEX 				Temp_Cust_Recommend(Recommend)
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Recommend (
			CTSCustID 			BIGINT  PRIMARY KEY 
        ,	CustID				BIGINT
        ,	Processed 			BIT DEFAULT 0
        ,	INDEX 				IX_Temp_Recommend_Recommend(CustID)
        ,	INDEX				IX_Temp_Recommend_Processed(Processed)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_GroupResult (
			OrigID 				BIGINT 
		,	DestID 				BIGINT 
		,	GroupID 			BIGINT
		,	PRIMARY KEY	(OrigID,DestID)
		,	INDEX			    IX_Temp_GroupResult(GroupID)
	);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupID;
	CREATE TEMPORARY TABLE 		Temp_GroupID (
			GroupID 			BIGINT PRIMARY KEY	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NodeCTSCustID;
	CREATE TEMPORARY TABLE 		Temp_NodeCTSCustID (
			CTSCustID 			BIGINT PRIMARY KEY
	);
	
	#=============================================================================	
	INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, Recommend)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Recommend
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),
							'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID 
														AND cus.IsInternal = 0
                                                        AND cus.RoleID = 1
                                                        AND cus.IsLicensee = 0;
														
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Dup;
	CREATE TEMPORARY TABLE Temp_Cust_Dup LIKE Temp_Cust;
	INSERT INTO Temp_Cust_Dup SELECT * FROM Temp_Cust;
														
	INSERT IGNORE INTO Temp_Recommend(CTSCustID, CustID)
	SELECT 	cus.CTSCustID
        ,	cus.CustID
	FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0;
														
	WITH CTE AS (
		SELECT DISTINCT 
				CTSCustID
			,	CustID
		FROM Temp_Recommend
    )
    SELECT JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', CustID)) AS CustJson
	INTO lv_AgentJson	
    FROM CTE;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend_Dup;
	CREATE TEMPORARY TABLE Temp_Recommend_Dup LIKE Temp_Recommend;
	INSERT INTO Temp_Recommend_Dup SELECT * FROM Temp_Recommend;
	
	CALL CTS_DataCenter.CTS_DC_Association_GetCustEdge(lv_AgentJson,1,0,0);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Graph_Dup;
	CREATE TEMPORARY TABLE Temp_Graph_Dup LIKE Temp_Graph;
	INSERT INTO Temp_Graph_Dup 
	SELECT grp.* 
	FROM Temp_Graph AS grp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = grp.OrigID AND cus.IsInternal = 0
		INNER JOIN CTS_DataCenter.CTSCustomer AS dup ON dup.CTSCustID = grp.DestID AND cus.IsInternal = 0;

	lp: LOOP 
		SET lv_OrigID = NULL;
		
		SELECT CTSCustID
        INTO lv_OrigID
		FROM Temp_Recommend
        WHERE Processed = 0
		LIMIT 1;
		
		IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
        
		UPDATE Temp_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE tmp.CTSCustID = lv_OrigID;
        
		INSERT IGNORE INTO Temp_NodeCTSCustID(CTSCustID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT CASE WHEN CTE_Group.OrigID = grp.DestID THEN grp.OrigID ELSE grp.DestID END
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.OrigID OR CTE_Group.OrigID = grp.DestID
		) 
		SELECT cte.OrigID
        FROM CTE_Group AS cte
		WHERE EXISTS (SELECT 1 FROM Temp_Recommend AS tmp WHERE tmp.CTSCustID = cte.OrigID);
        
		SELECT COUNT(1)
        INTO lv_Count
        FROM Temp_NodeCTSCustID;
		
		IF lv_Count IS NULL OR lv_Count = 1 THEN
			TRUNCATE TABLE Temp_NodeCTSCustID;
        END IF;
		
		INSERT IGNORE INTO Temp_GroupID(GroupID)
        SELECT DISTINCT 
				gr.GroupID
        FROM Temp_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_NodeCTSCustID AS tmp WHERE gr.OrigID = tmp.CTSCustID);
		
		IF EXISTS (SELECT 1 FROM Temp_GroupID) THEN
			UPDATE Temp_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_GroupID AS tmp WHERE gr.OrigID = tmp.GroupID);
        END IF;
		
		INSERT IGNORE Temp_GroupResult(OrigID,DestID,GroupID)
        SELECT 	lv_OrigID
            ,	CTSCustID
            ,	lv_GroupID
        FROM Temp_NodeCTSCustID;
		
		UPDATE Temp_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_GroupResult AS gp WHERE  gp.DestID = tmp.CTSCustID);
        
		SET lv_GroupID = lv_GroupID + 1;
        TRUNCATE TABLE Temp_NodeCTSCustID;
        TRUNCATE TABLE Temp_GroupID;
	
	END LOOP;

	SELECT 	cus.CTSCustID AS OrigID 
		 ,	cusd.CTSCustID AS DestID
    FROM Temp_GroupResult AS grp
		INNER JOIN Temp_Recommend AS re ON re.CTSCustID = grp.OrigID
		INNER JOIN Temp_Recommend_Dup AS red ON red.CTSCustID = grp.DestID
        INNER JOIN Temp_Cust AS cus ON re.CustID = cus.Recommend
		INNER JOIN Temp_Cust_Dup AS cusd ON red.CustID = cusd.Recommend
	WHERE grp.OrigID <> grp.DestID;
	
END$$

DELIMITER ;