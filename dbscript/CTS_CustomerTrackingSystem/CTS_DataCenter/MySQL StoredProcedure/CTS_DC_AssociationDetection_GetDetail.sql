/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_GetDetail`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_GetDetail`(
		IN	ip_CTSCustID 				BIGINT UNSIGNED
	,	IN	ip_ListCTSCustID 			LONGTEXT
	,   IN  ip_HasDevice				BIT
    ,   IN  ip_HasAI					BIT
    ,   IN  ip_HasIP					BIT 
    ,	IN	ip_HasAgent 				BIT 
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*  
		Created:	20220727@Aries.Nguyen
		Task:		[CTS] Enhance Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20220727@Aries.Nguyen: Created [Redmine ID: #175701]
            - 20221205@Aries.Nguyen: Re-arrange type options on Association Detection  [Redmine ID: #181207]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetDetail(1,'1,2',1,1,1,1,1);
	*/
    DECLARE CONS_RangeDevice 		BIGINT DEFAULT 10000000000;
    DECLARE lv_CTSCustIDs 			JSON;
    DECLARE lv_AgentCTSCustIDs 		JSON;
    DECLARE lv_CustID 				BIGINT UNSIGNED;
    DECLARE lv_RoleID 				INT;
    DECLARE lv_Username 			VARCHAR(50);
    DECLARE lv_RecommendCustID 		BIGINT UNSIGNED;
    DECLARE lv_RecommendCTSCustID 	BIGINT UNSIGNED;
    DECLARE lv_RecommendUsername 	VARCHAR(50);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		,	CustID 			BIGINT UNSIGNED
        ,	Username		VARCHAR(50)
        ,	Recommend		BIGINT
        ,	RoleID			INT
        ,	INDEX			IX_Temp_Cust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Dup;
	CREATE TEMPORARY TABLE 		Temp_Cust_Dup (
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Recommend (
			CTSCustID 			BIGINT  PRIMARY KEY 
        ,	Recommend			BIGINT
        ,	Username			VARCHAR(50)
        ,	INDEX 				IX_Temp_Recommend_Recommend(Recommend)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend_Dup;
	CREATE TEMPORARY TABLE 	Temp_Recommend_Dup (
			CTSCustID 			BIGINT  PRIMARY KEY 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GraphOrig;
    CREATE TEMPORARY TABLE 	Temp_GraphOrig (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
		,	AssociationType		SMALLINT 
		,	PRIMARY KEY(OrigID, DestID,AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    CREATE TEMPORARY TABLE 	Temp_Association (
			CTSCustID 				BIGINT  
		,	Transitive   			BIGINT
		,	AssociationType1		SMALLINT 
        ,	AssociationType2		SMALLINT 
        ,	PRIMARY KEY(CTSCustID, Transitive, AssociationType1, AssociationType2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AgentAssociation;
    CREATE TEMPORARY TABLE 	Temp_AgentAssociation (
			CTSCustID 				BIGINT  
		,	Transitive   			BIGINT
		,	AssociationType1		SMALLINT 
        ,	AssociationType2		SMALLINT 
        ,	PRIMARY KEY(CTSCustID, Transitive, AssociationType1, AssociationType2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Level1;
    CREATE TEMPORARY TABLE 	Temp_Level1 (
			CTSCustID 				BIGINT  PRIMARY KEY
		,	AssociationType			VARCHAR(100) 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Level2;
    CREATE TEMPORARY TABLE 	Temp_Level2 (
			CTSCustID 				BIGINT  PRIMARY KEY
		,	Transitive				BIGINT
		,	AssociationType1		VARCHAR(100) 
        ,	AssociationType2		VARCHAR(100) 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AgentLevel1;
    CREATE TEMPORARY TABLE 	Temp_AgentLevel1 (
			CTSCustID 				BIGINT  PRIMARY KEY
		,	AssociationType			VARCHAR(100) 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AgentLevel2;
    CREATE TEMPORARY TABLE 	Temp_AgentLevel2 (
			CTSCustID 				BIGINT  PRIMARY KEY
		,	Transitive				BIGINT
		,	AssociationType1		VARCHAR(100) 
        ,	AssociationType2		VARCHAR(100) 
	);
   
    DROP TEMPORARY TABLE IF EXISTS Temp_AgentResult;
	CREATE TEMPORARY TABLE 		Temp_AgentResult (
			CTSCustID				BIGINT UNSIGNED PRIMARY KEY
		,	CustID					BIGINT UNSIGNED
		,	Username				VARCHAR(50)
		,	AgentUsername			VARCHAR(50)	
        ,	TransitiveCTSCustID		BIGINT
        ,	TransitiveUsername		VARCHAR(50)
		,	AssociationType1		VARCHAR(100) 
        ,	AssociationType2		VARCHAR(100) 
	);

    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, Username, Recommend, RoleID)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Username
        ,	cus.Recommend	
		,	cus.RoleID
	FROM JSON_TABLE(CONCAT('[',ip_ListCTSCustID,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID;
	
    INSERT INTO Temp_Cust_Dup(CTSCustID)
    SELECT CTSCustID
    FROM Temp_Cust;
    
    SELECT 	CustID
		,	Username
        ,	Recommend
        ,	RoleID
	INTO 	lv_CustID
		,	lv_Username
        ,	lv_RecommendCustID
        ,	lv_RoleID
    FROM CTSCustomer 
    WHERE CTSCustID = ip_CTSCustID;
    
    SELECT 	CTSCustID
		,	Username
	INTO 	lv_RecommendCTSCustID
		,	lv_RecommendUsername
    FROM CTSCustomer 
    WHERE CustID = lv_RecommendCustID
		AND CustSubID = 0;
	
	INSERT IGNORE INTO Temp_Recommend(CTSCustID,Username, Recommend)
    SELECT 	cus.CTSCustID
		,	cus.Username
        ,	tmp.Recommend
    FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0
                                                        AND tmp.Recommend != lv_RecommendCustID;
	INSERT IGNORE INTO Temp_Recommend_Dup(CTSCustID)
    SELECT CTSCustID
    FROM Temp_Recommend;
    
    WITH CTE AS (
		SELECT 	DISTINCT
				CTSCustID
			,	CustID
        FROM Temp_Cust
    )
    SELECT JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', CustID)) AS CustJson
	INTO lv_CTSCustIDs	
    FROM CTE;
    
    CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetEdgeByCust(ip_CTSCustID,lv_CTSCustIDs,ip_HasDevice,ip_HasAI,ip_HasIP);
	
    INSERT INTO Temp_GraphOrig(OrigID, DestID, AssociationType)
	SELECT 	OrigID
		,	DestID
        ,	AssociationType
    FROM Temp_Graph 
    WHERE	OrigID = ip_CTSCustID;
    
    INSERT IGNORE INTO Temp_Association(CTSCustID, Transitive, AssociationType1, AssociationType2)
    WITH RECURSIVE CTE_Group AS ( 
				SELECT 	DestID     #CAST(CONCAT(OrigID, ' -> ', DestID) AS CHAR(2000)) AS CurPath
                    , 	CASE WHEN DestID < CONS_RangeDevice THEN DestID ELSE 0 END AS Transitive
                    ,	CASE WHEN DestID < CONS_RangeDevice THEN AssociationType ELSE 0 END AS AssociationType1
                    ,	0 AS AssociationType2
                FROM Temp_GraphOrig
				UNION ALL
                SELECT 	grp.DestID       #CONCAT(CTE_Group.CurPath, ' -> ', grp.DestID)
                    ,	CASE WHEN grp.DestID > CONS_RangeDevice  OR EXISTS (SELECT 1 FROM Temp_Cust AS cus WHERE cus.CTSCustID = grp.DestID) THEN CTE_Group.Transitive
							 ELSE grp.DestID END AS Transitive
					,   CASE WHEN  CTE_Group.AssociationType1 > 0 THEN CTE_Group.AssociationType1  
                             WHEN  CTE_Group.AssociationType1 = 0 AND  grp.DestID < CONS_RangeDevice THEN grp.AssociationType 
							 ELSE 0 
                             END AS AssociationType1
				    ,   CASE WHEN grp.DestID < CONS_RangeDevice AND CTE_Group.AssociationType1 > 0 THEN grp.AssociationType 
							 ELSE 0 
							 END AS AssociationType2
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON grp.OrigID = CTE_Group.DestID
				LIMIT 1000000
	) 
	SELECT 	cte.DestID
		,	cte.Transitive
        ,	cte.AssociationType1
        ,	cte.AssociationType2
	FROM CTE_Group AS cte
	WHERE EXISTS (SELECT 1 FROM Temp_Cust_Dup AS tmp WHERE tmp.CTSCustID = cte.DestID);
    
    IF ip_HasAgent = 1 AND lv_RoleID = 1 THEN
		TRUNCATE TABLE Temp_GraphOrig;
        
		SELECT 	JSON_ARRAYAGG(JSON_OBJECT('CTSCustID', CTSCustID ,'CustID', NULL)) AS CustJson
		INTO lv_AgentCTSCustIDs
		FROM Temp_Recommend;
		
        CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetEdgeByCust(lv_RecommendCTSCustID,lv_AgentCTSCustIDs,ip_HasDevice,ip_HasAI,ip_HasIP);
        
        INSERT INTO Temp_GraphOrig(OrigID, DestID, AssociationType)
		SELECT 	OrigID
			,	DestID
			,	AssociationType
		FROM Temp_Graph 
		WHERE	OrigID = lv_RecommendCTSCustID;
        
        INSERT IGNORE INTO Temp_AgentAssociation(CTSCustID, Transitive, AssociationType1, AssociationType2)
		WITH RECURSIVE CTE_Group AS ( 
					SELECT 	DestID     #CAST(CONCAT(OrigID, ' -> ', DestID) AS CHAR(2000)) AS CurPath
						, 	0 AS Transitive
						,	 CASE WHEN DestID < CONS_RangeDevice THEN AssociationType 
								  ELSE 0 
							 END AS AssociationType1
						,	0 AS AssociationType2
					FROM Temp_GraphOrig
					UNION ALL
					SELECT 	grp.DestID       #CONCAT(CTE_Group.CurPath, ' -> ', grp.DestID)
						,	CASE WHEN grp.DestID > CONS_RangeDevice  OR EXISTS (SELECT 1 FROM Temp_Recommend AS cus WHERE cus.CTSCustID = grp.DestID) THEN CTE_Group.Transitive
								 ELSE grp.DestID END AS Transitive
						,   CASE WHEN  CTE_Group.AssociationType1 > 0 THEN CTE_Group.AssociationType1  
								 WHEN  CTE_Group.AssociationType1 = 0 AND  grp.DestID < CONS_RangeDevice THEN grp.AssociationType 
								 ELSE 0 
								 END AS AssociationType1
						,   CASE WHEN grp.DestID < CONS_RangeDevice AND CTE_Group.AssociationType1 > 0 THEN grp.AssociationType 
								 ELSE 0 
								 END AS AssociationType2
					FROM Temp_Graph  AS grp
						INNER JOIN CTE_Group ON grp.OrigID = CTE_Group.DestID
					LIMIT 1000000
		) 
		SELECT 	cte.DestID
			,	cte.Transitive 
			,	cte.AssociationType1
			,	cte.AssociationType2
		FROM CTE_Group AS cte
		WHERE EXISTS (SELECT 1 FROM Temp_Recommend_Dup AS tmp WHERE tmp.CTSCustID = cte.DestID);
        
        INSERT INTO Temp_AgentLevel1(CTSCustID,AssociationType)
		SELECT 	lv1.CTSCustID
			,	GROUP_CONCAT(DISTINCT CASE WHEN lv1.AssociationType1 = 1 THEN "Device"
										   WHEN lv1.AssociationType1 = 2 THEN "Manual"
										   WHEN lv1.AssociationType1 IN (3,4) THEN "Betting Pattern"
										   WHEN lv1.AssociationType1 = 5 THEN "IP" 
									   END) AS AssociationType
		FROM Temp_AgentAssociation AS lv1
		WHERE lv1.AssociationType1 != 0
			AND lv1.AssociationType2 = 0
		GROUP BY lv1.CTSCustID;
        
        INSERT IGNORE INTO Temp_AgentLevel2(CTSCustID,Transitive,AssociationType1,AssociationType2)
		SELECT 	cus.CTSCustID
			,	lv2.Transitive
			,	CASE WHEN lv2.AssociationType1 = 1 THEN "Device"
					 WHEN lv2.AssociationType1 IN (3,4) THEN "Betting Pattern"
					 WHEN lv2.AssociationType1 = 5 THEN "IP" 
				END AS AssociationType1
			,	CASE WHEN lv2.AssociationType2 = 1 THEN "Device"
					 WHEN lv2.AssociationType2 IN (3,4) THEN "Betting Pattern"
					 WHEN lv2.AssociationType2 = 5 THEN "IP" 
				END AS AssociationType2
		FROM Temp_Recommend AS cus,
			LATERAL(SELECT 	tmp.Transitive
						,	tmp.AssociationType1
						,	tmp.AssociationType2
					FROM Temp_Association AS tmp 
					WHERE tmp.CTSCustID = cus.CTSCustID
						AND tmp.Transitive != 0
					ORDER BY tmp.Transitive ASC
						,	 tmp.AssociationType1 ASC
						,	 tmp.AssociationType1 ASC
					LIMIT 1) AS lv2
		WHERE NOT EXISTS (SELECT 1 FROM Temp_AgentLevel1 AS lv1 WHERE cus.CTSCustID = lv1.CTSCustID);
		
		INSERT IGNORE INTO Temp_AgentLevel2(CTSCustID,Transitive,AssociationType1,AssociationType2)
		SELECT 	CTSCustID
			,	0 AS Transitive
			,	AssociationType AS AssociationType1
			,	"" AS AssociationType2
		FROM Temp_AgentLevel1;
        
		INSERT IGNORE INTO Temp_AgentResult( CTSCustID,CustID,Username,AgentUsername,TransitiveCTSCustID,TransitiveUsername,AssociationType1,AssociationType2)
        SELECT 	cus.CTSCustID
			,	cus.CustID 
			,	cus.Username
			,	re.Username AS AgentUsername
            ,	transitive.CTSCustID AS TransitiveCTSCustID
            ,	transitive.Username AS TransitiveUsername
			,	lv.AssociationType1
            ,	lv.AssociationType2
		FROM Temp_AgentLevel2 AS lv
			INNER JOIN Temp_Recommend AS re ON re.CTSCustID = lv.CTSCustID
			INNER JOIN Temp_Cust AS cus ON cus.Recommend = re.Recommend AND cus.RoleID = 1
			LEFT JOIN CTSCustomer AS transitive ON transitive.CTSCustID = lv.Transitive;

    END IF;
   
    INSERT INTO Temp_Level1(CTSCustID,AssociationType)
    SELECT 	lv1.CTSCustID
		,	GROUP_CONCAT(DISTINCT CASE WHEN lv1.AssociationType1 = 1 THEN "Device"
									   WHEN lv1.AssociationType1 = 2 THEN "Manual"
									   WHEN lv1.AssociationType1 IN (3,4) THEN "Betting Pattern"
									   WHEN lv1.AssociationType1 = 5 THEN "IP" 
								   END) AS AssociationType
    FROM Temp_Association AS lv1
    WHERE lv1.AssociationType1 != 0
		AND lv1.AssociationType2 = 0
	GROUP BY lv1.CTSCustID;
    
    INSERT IGNORE INTO Temp_Level2(CTSCustID,Transitive,AssociationType1,AssociationType2)
    SELECT 	cus.CTSCustID
		,	lv2.Transitive
        ,	CASE WHEN lv2.AssociationType1 = 1 THEN "Device"
				 WHEN lv2.AssociationType1 IN (3,4) THEN "Betting Pattern"
				 WHEN lv2.AssociationType1 = 5 THEN "IP" 
			END AS AssociationType1
		,	CASE WHEN lv2.AssociationType2 = 1 THEN "Device"
				 WHEN lv2.AssociationType2 IN (3,4) THEN "Betting Pattern"
				 WHEN lv2.AssociationType2 = 5 THEN "IP" 
			END AS AssociationType2
    FROM Temp_Cust AS cus,
		LATERAL(SELECT 	tmp.Transitive
					,	tmp.AssociationType1
                    ,	tmp.AssociationType2
			    FROM Temp_Association AS tmp 
                WHERE tmp.CTSCustID = cus.CTSCustID
					AND tmp.Transitive != 0
				ORDER BY tmp.Transitive ASC
					,	 tmp.AssociationType1 ASC
                    ,	 tmp.AssociationType1 ASC
				LIMIT 1) AS lv2
	WHERE NOT EXISTS (SELECT 1 FROM Temp_Level1 AS lv1 WHERE cus.CTSCustID = lv1.CTSCustID);
    
    INSERT INTO Temp_Level2(CTSCustID,Transitive,AssociationType1,AssociationType2)
    SELECT 	CTSCustID
		,	0 AS Transitive
        ,	AssociationType AS AssociationType1
        ,	"" AS AssociationType2
    FROM Temp_Level1;
    
    SELECT 	ip_CTSCustID AS FromCTSCustID
		,	lv_CustID AS FromCustID
        ,	lv_Username AS FromUsername
        ,	lv_RecommendUsername AS FromAgentUsername
        
        ,	lv.CTSCustID AS ToCTSCustID
        ,	cus.CustID AS ToCustID
        ,	cus.Username AS ToUsername
        ,	re.Username AS ToAgentUsername
        
        ,	lv.AssociationType1
        ,	lv.AssociationType2
        ,	"" AS AgentAssociationType1
        ,	"" AS AgentAssociationType2
        
        ,	lv.Transitive AS TransitiveCTSCustID
        ,	transitive.Username AS TransitiveUsername	
    FROM Temp_Level2 AS lv
		LEFT JOIN Temp_Cust AS cus ON cus.CTSCustID = lv.CTSCustID
        LEFT JOIN Temp_Recommend AS re ON re.CTSCustID = lv.CTSCustID
        LEFT JOIN CTSCustomer AS transitive ON transitive.CTSCustID = lv.Transitive
	 
	UNION ALL
    
    SELECT	ip_CTSCustID AS FromCTSCustID
		,	lv_CustID AS FromCustID
        ,	lv_Username AS FromUsername
        ,	lv_RecommendUsername AS FromAgentUsername
        
        ,	ag.CTSCustID AS ToCTSCustID
        ,	ag.CustID AS ToCustID
        ,	ag.Username AS ToUsername
        ,	ag.AgentUsername AS ToAgentUsername
        
        ,	"" AS AssociationType1
        ,	"" AS AssociationType2
        ,	ag.AssociationType1 AS AgentAssociationType1
        ,	ag.AssociationType2 AS AgentAssociationType2
        
        ,	ag.TransitiveCTSCustID
        ,	ag.TransitiveUsername	
    FROM Temp_AgentResult AS ag;

END$$

DELIMITER ;
