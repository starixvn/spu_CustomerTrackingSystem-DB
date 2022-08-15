/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_GetDetail`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_GetDetail`(
		IN	ip_CTSCustID 				BIGINT UNSIGNED
	,	IN	ip_ListCTSCustID 			LONGTEXT
	,	IN	ip_HasPrimary 				BIT 
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

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_GetCust(1,'1,2',1,1,1,1,1);
	*/
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Recommend (
			CTSCustID 			BIGINT  PRIMARY KEY 
        ,	Recommend			BIGINT
        ,	Username			VARCHAR(50)
        ,	INDEX 				IX_Temp_Recommend_Recommend(Recommend)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level0;
	CREATE TEMPORARY TABLE 		Temp_Device_Level0 (
		    DCSDeviceID			BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group_Level0;
	CREATE TEMPORARY TABLE 		Temp_Group_Level0 (
		    GroupID			BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Level1;
	CREATE TEMPORARY TABLE 		Temp_Level1 (
		    CTSCustID			BIGINT UNSIGNED 
		,	AssociationType		SMALLINT 
        ,	PRIMARY KEY(CTSCustID, AssociationType) # 1-Device, 2-Manual, 3-AI, 4-AIGroup, 5-IP, 6 - Agent, 7 - SharedIP, 8 - SharedMatches		
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
	CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
        ,	INDEX				IX_Temp_Graph_DestID(DestID)
        ,	PRIMARY KEY(OrigID, DestID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GraphCount;
	CREATE TEMPORARY TABLE 	Temp_GraphCount (
			DestID   			BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GraphGroupAss;
	CREATE TEMPORARY TABLE 	Temp_GraphGroupAss (
			DestID   			BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE 		Temp_Association (
			CTSCustID			BIGINT UNSIGNED
		,	AssociationType		VARCHAR(15)
        ,	PRIMARY KEY(CTSCustID, AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Agent;
	CREATE TEMPORARY TABLE 		Temp_Association_Agent (
			CTSCustID			BIGINT UNSIGNED
		,	AssociationType		VARCHAR(15)
        ,	PRIMARY KEY(CTSCustID, AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AgentResult;
	CREATE TEMPORARY TABLE 		Temp_AgentResult (
			CTSCustID				BIGINT UNSIGNED PRIMARY KEY
		,	CustID					BIGINT UNSIGNED
		,	Username				VARCHAR(50)
		,	AgentUsername			VARCHAR(50)	
		,	AgentAssociationType	VARCHAR(50)
	);
    
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, Username, Recommend, RoleID)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Username
        ,	cus.Recommend	
		,	cus.RoleID
	FROM JSON_TABLE(CONCAT('[',ip_ListCTSCustID,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID;

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
    
    IF ip_HasPrimary = 1 THEN
		/*---------------------------------------------Get Device--------------------------------------- */
		INSERT INTO Temp_Device_Level0(DCSDeviceID)
		SELECT 	dv.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS dv 
        WHERE dv.CTSCustID = ip_CTSCustID;
        
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	ip_CTSCustID
			, 	-1 * DCSDeviceID
		FROM Temp_Device_Level0;
        
        INSERT IGNORE INTO Temp_Level1(CTSCustID,AssociationType)
        SELECT 	lv1.CTSCustID 
			,	1 AS Device
        FROM CTS_DataCenter.AssociationByDevice AS lv1
        WHERE EXISTS (SELECT 1 FROM Temp_Device_Level0 AS dv WHERE lv1.DCSDeviceID = dv.DCSDeviceID)
			AND lv1.CTSCustID != ip_CTSCustID;
      
        /*---------------------------------------------Get Association Manual --------------------------------------- */
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  CASE WHEN ma.FromCTSCustID = ip_CTSCustID THEN ma.ToCTSCustID
					 ELSE  ma.FromCTSCustID END CTSCustID
			,  	2 AS Manual
		FROM CTS_DataCenter.AssociationByManual AS ma 
		WHERE ma.FromCTSCustID = ip_CTSCustID 
			OR ma.ToCTSCustID = ip_CTSCustID;
            
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  ma.FromCTSCustID
			,	ma.ToCTSCustID
		FROM Temp_Cust AS tmp
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = tmp.CTSCustID;
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  ma.ToCTSCustID 
			,	ma.FromCTSCustID
		FROM Temp_Cust AS tmp
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID;

        /*----------------------------------------------Get association by AI-------------------------------------------*/
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  cus.CTSCustID
			,  	3 AS AI
		FROM CTS_DataCenter.AssociationByAI AS ai
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.ToCustID = cus.CustID AND cus.CustSubID = 0
		WHERE ai.FromCustID = lv_CustID;
		
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  cus.CTSCustID
			,  	3 AS AI
		FROM CTS_DataCenter.AssociationByAI AS ai 
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.FromCustID = cus.CustID AND cus.CustSubID = 0
		WHERE ai.ToCustID = lv_CustID;
        
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  tmp.CTSCustID
			,	cus.CTSCustID
		FROM Temp_Cust AS tmp
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.ToCustID = cus.CustID AND cus.CustSubID = 0;
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  tmp.CTSCustID
			,	cus.CTSCustID
		FROM Temp_Cust AS tmp
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.FromCustID = cus.CustID AND cus.CustSubID = 0;

        /*----------------------------------------------Get AssociationGroupByAI-------------------------------------------*/
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	cus.CTSCustID 
			, 	-100000000000 + asg.GroupID
		FROM CTS_DataCenter.AssociationGroupByAI AS asg 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON asg.CustID = cus.CustID AND cus.CustSubID = 0
        WHERE asg.CustID = lv_CustID;
        
        INSERT INTO Temp_Group_Level0(GroupID)
		SELECT 	asg.GroupID 
		FROM CTS_DataCenter.AssociationGroupByAI AS asg 
        WHERE asg.CustID = lv_CustID;
        
        INSERT INTO Temp_Level1(CTSCustID,AssociationType)
        SELECT 	cus.CTSCustID 
			,	3 AS AI
        FROM CTS_DataCenter.AssociationGroupByAI AS lv1
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CustID = cus.CustID AND cus.CustSubID = 0
        WHERE EXISTS (SELECT 1 FROM Temp_Group_Level0 AS asg WHERE lv1.GroupID = asg.GroupID)
			AND lv1.CustID != lv_CustID;
            
        /*------------------------------------------Get association by IP-------------------------------------------------*/
        INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  cus.CTSCustID
			,  	4 AS IP
		FROM CTS_DataCenter.AssociationByIP AS ip
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.ToCustID = cus.CustID AND cus.CustSubID = 0
		WHERE ip.FromCustID = lv_CustID;
		
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  cus.CTSCustID
			,  	4 AS IP
		FROM CTS_DataCenter.AssociationByIP AS ip 
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.FromCustID = cus.CustID AND cus.CustSubID = 0
		WHERE ip.ToCustID = lv_CustID;
        
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  tmp.CTSCustID
			,	cus.CTSCustID
		FROM Temp_Cust AS tmp
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.ToCustID = cus.CustID AND cus.CustSubID = 0;
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  tmp.CTSCustID
			,	cus.CTSCustID
		FROM Temp_Cust AS tmp
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.FromCustID = cus.CustID AND cus.CustSubID = 0;
				
        /*------------------------------------------Build Graph Table-------------------------------------------------*/
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	ip_CTSCustID
			, 	CTSCustID
		FROM Temp_Level1;
        
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	ip_CTSCustID
			, 	-1 * dv.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS dv 
			INNER JOIN Temp_Level1 AS lv1 ON dv.CTSCustID = lv1.CTSCustID;
		
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	cus.CTSCustID
			, 	-1 * dv.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS dv 
			INNER JOIN Temp_Cust AS cus ON dv.CTSCustID = cus.CTSCustID;
              
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	ip_CTSCustID
			, 	-100000000000 + asg.GroupID
		FROM Temp_Level1 AS lv1 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = lv1.CTSCustID
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON cus.CustID = asg.CustID;
		
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	ip_CTSCustID
			, 	-100000000000 + asg.GroupID
		FROM Temp_Cust AS lv1 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = lv1.CTSCustID
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON cus.CustID = asg.CustID;
        
        INSERT IGNORE INTO Temp_Association(CTSCustID,AssociationType)
        SELECT 	lv1.CTSCustID
			,	CASE WHEN lv1.AssociationType = 1 THEN "Device"
					 WHEN lv1.AssociationType = 2 THEN "Manual"
					 WHEN lv1.AssociationType = 3 THEN "Betting Pattern"
					 WHEN lv1.AssociationType = 4 THEN "IP"
                ELSE "N/A" END AssociationType
        FROM  Temp_Level1 AS lv1  
		WHERE EXISTS (SELECT 1 FROM Temp_Cust AS cus WHERE lv1.CTSCustID = cus.CTSCustID);

        DELETE 
        FROM Temp_Graph AS grp
        WHERE EXISTS (SELECT 1 FROM Temp_Association AS lv1 WHERE lv1.CTSCustID = grp.OrigID);
        
        INSERT INTO Temp_GraphCount(DestID)
        SELECT DestID
        FROM Temp_Graph
        GROUP BY DestID
        HAVING COUNT(1) > 1;
        
        INSERT IGNORE INTO Temp_GraphGroupAss(DestID)
        SELECT grp.DestID
        FROM Temp_Graph AS grp
			INNER JOIN Temp_GraphCount AS tmp ON grp.OrigID = ip_CTSCustID  AND grp.DestID = tmp.DestID;
        
        INSERT INTO Temp_Association(CTSCustID,AssociationType)
        SELECT 	cus.CTSCustID
			,	""
        FROM Temp_Cust AS cus
			INNER JOIN Temp_Graph AS grp ON cus.CTSCustID = grp.OrigID
            INNER JOIN Temp_GraphGroupAss AS tmp ON tmp.DestID = grp.DestID;
    END IF;
    
    IF ip_HasAgent = 1 AND lv_RoleID = 1 THEN
		TRUNCATE TABLE Temp_Graph;
        TRUNCATE TABLE Temp_Device_Level0;
        TRUNCATE TABLE Temp_Level1;
        TRUNCATE TABLE Temp_GraphCount;
		TRUNCATE TABLE  Temp_GraphGroupAss;
        
        INSERT INTO Temp_Device_Level0(DCSDeviceID)
		SELECT 	dv.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS dv 
        WHERE dv.CTSCustID = lv_RecommendCTSCustID;
        
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	lv_RecommendCTSCustID 
			, 	-1 * DCSDeviceID
		FROM Temp_Device_Level0;
        
        INSERT IGNORE INTO Temp_Level1(CTSCustID,AssociationType)
        SELECT 	lv1.CTSCustID 
			,	1 AS Device
        FROM CTS_DataCenter.AssociationByDevice AS lv1
        WHERE EXISTS (SELECT 1 FROM Temp_Device_Level0 AS dv WHERE lv1.DCSDeviceID = dv.DCSDeviceID)
			AND lv1.CTSCustID != lv_RecommendCTSCustID;
        
        /*---------------------------------------------Get Association Manual --------------------------------------- */
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  CASE WHEN ma.FromCTSCustID = lv_RecommendCTSCustID THEN ma.ToCTSCustID
					 ELSE  ma.FromCTSCustID END CTSCustID
			,  	2 AS Manual
		FROM CTS_DataCenter.AssociationByManual AS ma 
		WHERE ma.FromCTSCustID = lv_RecommendCTSCustID 
			OR ma.ToCTSCustID = lv_RecommendCTSCustID;
            
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  ma.FromCTSCustID
			,	ma.ToCTSCustID
		FROM Temp_Recommend AS tmp
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = tmp.CTSCustID;
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT  ma.ToCTSCustID 
			,	ma.FromCTSCustID
		FROM Temp_Recommend AS tmp
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID;
		
        /*------------------------------------------Build Graph Table-------------------------------------------------*/
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	lv_RecommendCTSCustID
			, 	CTSCustID
		FROM Temp_Level1;
        
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	lv_RecommendCTSCustID
			, 	-1 * dv.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS dv 
			INNER JOIN Temp_Level1 AS lv1 ON dv.CTSCustID = lv1.CTSCustID;
		
        INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
		SELECT 	cus.CTSCustID
			, 	-1 * dv.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS dv 
			INNER JOIN Temp_Recommend AS cus ON dv.CTSCustID = cus.CTSCustID;

        INSERT IGNORE INTO Temp_Association_Agent(CTSCustID,AssociationType)
        SELECT 	lv1.CTSCustID
			,	CASE WHEN lv1.AssociationType = 1 THEN "Device"
					 WHEN lv1.AssociationType = 2 THEN "Manual"
                ELSE "N/A" END AssociationType
        FROM  Temp_Level1 AS lv1  
		WHERE EXISTS (SELECT 1 FROM Temp_Recommend AS cus WHERE lv1.CTSCustID = cus.CTSCustID);
        
        DELETE 
        FROM Temp_Graph AS grp
        WHERE EXISTS (SELECT 1 FROM Temp_Association_Agent AS lv1 WHERE lv1.CTSCustID = grp.OrigID);
        
        INSERT INTO Temp_GraphCount(DestID)
        SELECT DestID
        FROM Temp_Graph
        GROUP BY DestID
        HAVING COUNT(1) > 1;
        
        INSERT IGNORE INTO Temp_GraphGroupAss(DestID)
        SELECT grp.DestID
        FROM Temp_Graph AS grp
			INNER JOIN Temp_GraphCount AS tmp ON grp.OrigID = lv_RecommendCTSCustID  AND grp.DestID = tmp.DestID;
        
        INSERT INTO Temp_Association_Agent(CTSCustID,AssociationType)
        SELECT 	cus.CTSCustID
			,	""
        FROM Temp_Recommend AS cus
			INNER JOIN Temp_Graph AS grp ON cus.CTSCustID = grp.OrigID
            INNER JOIN Temp_GraphGroupAss AS tmp ON tmp.DestID = grp.DestID;
    
        INSERT IGNORE INTO Temp_AgentResult(CTSCustID,CustID,Username,AgentUsername,AgentAssociationType)
        SELECT 	cus.CTSCustID
			,	cus.CustID 
			,	cus.Username
			,	re.Username
			,	tbl.AgentAssociationType
		FROM(SELECT 	CTSCustID
				,		GROUP_CONCAT(DISTINCT AssociationType) AS AgentAssociationType
			FROM Temp_Association_Agent
			GROUP BY CTSCustID
		) AS tbl
			INNER JOIN Temp_Recommend AS re ON re.CTSCustID = tbl.CTSCustID
			INNER JOIN Temp_Cust AS cus ON cus.Recommend = re.Recommend AND cus.RoleID = 1;
    END IF;
    
    SELECT 	ip_CTSCustID AS FromCTSCustID
		,	lv_CustID AS FromCustID
        ,	lv_Username AS FromUsername
        ,	lv_RecommendUsername AS FromAgentUsername
        
        ,	lv.CTSCustID AS ToCTSCustID
        ,	cus.CustID AS ToCustID
        ,	cus.Username AS ToUsername
        ,	re.Username AS ToAgentUsername
        
        ,	lv.AssociationType
        ,	"" AS AgentAssociationType
    FROM Temp_Association AS lv
		LEFT JOIN Temp_Cust AS cus ON cus.CTSCustID = lv.CTSCustID
        LEFT JOIN Temp_Recommend AS re ON re.CTSCustID = lv.CTSCustID
        
	UNION ALL
    
    SELECT	ip_CTSCustID AS FromCTSCustID
		,	lv_CustID AS FromCustID
        ,	lv_Username AS FromUsername
        ,	lv_RecommendUsername AS FromAgentUsername
        
        ,	ag.CTSCustID AS ToCTSCustID
        ,	ag.CustID AS ToCustID
        ,	ag.Username AS ToUsername
        ,	ag.AgentUsername AS ToAgentUsername
        
        ,	"Agent" AS AssociationType
        ,	ag.AgentAssociationType
    FROM Temp_AgentResult AS ag;
    
END$$

DELIMITER ;
