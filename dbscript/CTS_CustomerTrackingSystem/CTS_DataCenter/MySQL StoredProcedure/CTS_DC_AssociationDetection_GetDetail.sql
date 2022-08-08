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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Level1;
	CREATE TEMPORARY TABLE 		Temp_Level1 (
			CTSCustID			BIGINT UNSIGNED
		,	CustID 				BIGINT UNSIGNED
		,	AssociationType		VARCHAR(15)
        ,	PRIMARY KEY(CTSCustID, AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AgentLevel1;
	CREATE TEMPORARY TABLE 		Temp_AgentLevel1 (
			CTSCustID			BIGINT UNSIGNED
		,	CustID 				BIGINT UNSIGNED
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
	INTO 	lv_CustID
		,	lv_Username
        ,	lv_RecommendCustID
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
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT 	lv1.CTSCustID
			,	"Device"
		FROM AssociationByDevice AS dv 
			INNER JOIN AssociationByDevice AS lv1 ON dv.DCSDeviceID = lv1.DCSDeviceID  
			INNER JOIN Temp_Cust AS cus ON cus.CTSCustID = lv1.CTSCustID
		WHERE dv.CTSCustID = ip_CTSCustID;
		
        INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT 	ma.ToCTSCustID
			,	"Manually"
		FROM AssociationByManual AS ma
			INNER JOIN Temp_Cust AS cus ON ma.ToCTSCustID = cus.CTSCustID
		WHERE ma.FromCTSCustID = ip_CTSCustID;
        
        INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT 	ma.FromCTSCustID
			,	"Manually"
		FROM AssociationByManual AS ma
			INNER JOIN Temp_Cust AS cus ON ma.FromCTSCustID = cus.CTSCustID
		WHERE ma.ToCTSCustID = ip_CTSCustID;
        
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			,	"Betting Pattern"
		FROM CTS_DataCenter.AssociationByAI AS ai 
			INNER JOIN Temp_Cust AS tmp ON ai.ToCustID = tmp.CustID 
		WHERE ai.FromCustID = lv_CustID;
		
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			,	"Betting Pattern"
		FROM CTS_DataCenter.AssociationByAI AS ai 
			INNER JOIN Temp_Cust AS tmp ON ai.FromCustID = tmp.CustID 
		WHERE ai.ToCustID = lv_CustID;
        
        INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT 	cus.CTSCustID
			,	"Betting Pattern"
		FROM AssociationGroupByAI AS aga 
			INNER JOIN AssociationGroupByAI AS lv1 ON aga.GroupID = lv1.GroupID  
			INNER JOIN Temp_Cust AS cus ON cus.CustID = lv1.CustID
		WHERE aga.CustID = lv_CustID;
        
        INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			,	"IP"
		FROM CTS_DataCenter.AssociationByIP AS ip 
			INNER JOIN Temp_Cust AS tmp ON ip.ToCustID = tmp.CustID 
		WHERE ip.FromCustID = lv_CustID;
		
		INSERT IGNORE INTO Temp_Level1(CTSCustID, AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			,	"IP"
		FROM CTS_DataCenter.AssociationByIP AS ip 
			INNER JOIN Temp_Cust AS tmp ON ip.FromCustID = tmp.CustID 
		WHERE ip.ToCustID = lv_CustID;
    END IF;
    
    IF ip_HasAgent = 1 THEN
		INSERT IGNORE INTO Temp_AgentLevel1(CTSCustID, AssociationType)
		SELECT 	lv1.CTSCustID
			,	"Device"
		FROM AssociationByDevice AS dv 
			INNER JOIN AssociationByDevice AS lv1 ON dv.DCSDeviceID = lv1.DCSDeviceID  
			INNER JOIN Temp_Recommend AS cus ON cus.CTSCustID = lv1.CTSCustID
		WHERE dv.CTSCustID = lv_RecommendCTSCustID;

        INSERT INTO Temp_AgentLevel1(CTSCustID, AssociationType)
		SELECT 	ma.ToCTSCustID
			,	"Manually"
		FROM AssociationByManual AS ma
			INNER JOIN Temp_Recommend AS cus ON ma.ToCTSCustID = cus.CTSCustID
		WHERE ma.FromCTSCustID = lv_RecommendCTSCustID;
        
        INSERT IGNORE INTO Temp_AgentLevel1(CTSCustID, AssociationType)
		SELECT 	ma.FromCTSCustID
			,	"Manually"
		FROM AssociationByManual AS ma
			INNER JOIN Temp_Recommend AS cus ON ma.FromCTSCustID = cus.CTSCustID
		WHERE ma.ToCTSCustID = lv_RecommendCTSCustID;
        
        INSERT IGNORE INTO Temp_AgentResult(CTSCustID,CustID,Username,AgentUsername,AgentAssociationType)
        SELECT 	cus.CTSCustID
			,	cus.CustID 
			,	cus.Username
			,	re.Username
			,	tbl.AgentAssociationType
		FROM(SELECT 	CTSCustID
				,		GROUP_CONCAT(DISTINCT AssociationType) AS AgentAssociationType
			FROM Temp_AgentLevel1
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
    FROM Temp_Level1 AS lv
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
