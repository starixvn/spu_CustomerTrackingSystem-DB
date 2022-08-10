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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE 		Temp_Association (
			CTSCustID			BIGINT UNSIGNED
		,	AssociationType		VARCHAR(15)
        ,	PRIMARY KEY(CTSCustID, AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level2;
	CREATE TEMPORARY TABLE 		Temp_Association_Level2 (
			CTSCustID			BIGINT UNSIGNED
        ,	PRIMARY KEY(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Level1_Group;
	CREATE TEMPORARY TABLE 	Temp_Level1_Group (
			CTSCustID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust		INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Level1_Group_Agent;
	CREATE TEMPORARY TABLE 	Temp_Level1_Group_Agent (
			CTSCustID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust		INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Distinct;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1_Distinct (
		    CTSCustID			BIGINT UNSIGNED 
		,	CTSCustID_Level1	BIGINT UNSIGNED	 
		,	PRIMARY KEY 		PK_Temp_Association_Level1_Distinct(CTSCustID_Level1, CTSCustID )
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Distinct_Agent;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1_Distinct_Agent (
		    CTSCustID			BIGINT UNSIGNED 
		,	CTSCustID_Level1	BIGINT UNSIGNED	 
		,	PRIMARY KEY 		PK_Temp_Association_Level1_Distinct_Agent(CTSCustID_Level1, CTSCustID )
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Agent;
	CREATE TEMPORARY TABLE 		Temp_Association_Agent (
			CTSCustID			BIGINT UNSIGNED
		,	AssociationType		VARCHAR(15)
        ,	PRIMARY KEY(CTSCustID, AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level2_Agent;
	CREATE TEMPORARY TABLE 		Temp_Association_Level2_Agent (
			CTSCustID			BIGINT UNSIGNED
        ,	PRIMARY KEY(CTSCustID)
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
	CREATE TEMPORARY TABLE 		Temp_CustDevice (
			CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level0;
	CREATE TEMPORARY TABLE 		Temp_Device_Level0 (
		    DCSDeviceID			BIGINT UNSIGNED PRIMARY KEY
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Level1;
	CREATE TEMPORARY TABLE 		Temp_CustDevice_Level1 (
		    CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level0;
	CREATE TEMPORARY TABLE 		Temp_Device_Level0 (
		    DCSDeviceID			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCust_Group;
	CREATE TEMPORARY TABLE 		Temp_DeviceCust_Group (
			DCSDeviceID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust			INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Agent;
	CREATE TEMPORARY TABLE 		Temp_CustDevice_Agent (
			CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level0_Agent;
	CREATE TEMPORARY TABLE 		Temp_Device_Level0_Agent (
		    DCSDeviceID			BIGINT UNSIGNED PRIMARY KEY
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Level1_Agent;
	CREATE TEMPORARY TABLE 		Temp_CustDevice_Level1_Agent (
		    CTSCustID			BIGINT UNSIGNED  
		 ,	DCSDeviceID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(DCSDeviceID, CTSCustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level0_Agent;
	CREATE TEMPORARY TABLE 		Temp_Device_Level0_Agent (
		    DCSDeviceID			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCust_Group_Agent;
	CREATE TEMPORARY TABLE 		Temp_DeviceCust_Group_Agent (
			DCSDeviceID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust			INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAIGroup;
	CREATE TEMPORARY TABLE 		Temp_CustAIGroup (
			CTSCustID			BIGINT UNSIGNED  
		 ,	GroupID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(GroupID, CTSCustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AIGroup_Level0;
	CREATE TEMPORARY TABLE 		Temp_AIGroup_Level0 (
		    GroupID			BIGINT UNSIGNED PRIMARY KEY
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAIGroup_Level1;
	CREATE TEMPORARY TABLE 		Temp_CustAIGroup_Level1 (
		    CTSCustID			BIGINT UNSIGNED  
		 ,	GroupID  		BIGINT UNSIGNED 
		 ,	PRIMARY KEY(GroupID, CTSCustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AIGroup_Level0;
	CREATE TEMPORARY TABLE 		Temp_AIGroup_Level0 (
		    GroupID			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AIGroupCust_Group;
	CREATE TEMPORARY TABLE 		Temp_AIGroupCust_Group (
			GroupID  		BIGINT UNSIGNED PRIMARY KEY
		 ,	TotalCust		INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1 (
		    CTSCustID			BIGINT UNSIGNED 
		,	CTSCustID_Level1	BIGINT UNSIGNED	 
        ,	AssociationType		VARCHAR(50)	
        ,	INDEX 				IX_Temp_Association_CTSCustID_Level1(CTSCustID_Level1)
        ,	PRIMARY KEY(CTSCustID,CTSCustID_Level1,AssociationType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Agent;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1_Agent (
		    CTSCustID			BIGINT UNSIGNED 
		,	CTSCustID_Level1	BIGINT UNSIGNED	 
        ,	AssociationType		VARCHAR(50)	
        ,	INDEX 				IX_Temp_Association_CTSCustID_Level1(CTSCustID_Level1)
        ,	PRIMARY KEY(CTSCustID,CTSCustID_Level1,AssociationType)
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
	
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, Username, Recommend, RoleID)
    VALUES (ip_CTSCustID,lv_CustID,lv_Username,lv_RecommendCustID,lv_RoleID);
    
    INSERT IGNORE INTO Temp_Recommend(CTSCustID, Username, Recommend)
    VALUES (lv_RecommendCTSCustID,lv_RecommendUsername,lv_RecommendCustID);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Duplicate;
	CREATE TEMPORARY TABLE Temp_Cust_Duplicate LIKE Temp_Cust;
	INSERT INTO Temp_Cust_Duplicate
	SELECT * FROM Temp_Cust;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend_Duplicate;
	CREATE TEMPORARY TABLE Temp_Recommend_Duplicate LIKE Temp_Recommend;
	INSERT INTO Temp_Recommend_Duplicate
	SELECT * FROM Temp_Recommend;
    
    IF ip_HasPrimary = 1 THEN
		INSERT IGNORE INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
		SELECT 	cus.CTSCustID 
			, 	dv.DCSDeviceID
		FROM Temp_Cust AS cus
			INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;
        
        INSERT INTO Temp_Device_Level0(DCSDeviceID)
		SELECT 	DISTINCT
				DCSDeviceID
		FROM Temp_CustDevice;
        
        INSERT IGNORE INTO Temp_CustDevice_Level1(CTSCustID,DCSDeviceID)
		SELECT  lv1.CTSCustID
			,	dv.DCSDeviceID
		FROM Temp_Device_Level0 AS dv
			INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON dv.DCSDeviceID =  lv1.DCSDeviceID;
        
        INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT 	cuDv.CTSCustID
			, 	lv1.CTSCustID
			,	"Device" AS AssociationType
		FROM Temp_CustDevice AS cuDv
			INNER JOIN Temp_CustDevice_Level1 AS lv1 ON cuDv.DCSDeviceID =  lv1.DCSDeviceID;
		
        INSERT INTO Temp_DeviceCust_Group(DCSDeviceID, TotalCust)
		SELECT 	DCSDeviceID
			, 	COUNT(1) AS TotalCust
		FROM Temp_CustDevice 
		GROUP BY DCSDeviceID;
        
        DELETE FROM Temp_CustDevice AS tmp
		WHERE tmp.DCSDeviceID IN (SELECT grp.DCSDeviceID FROM Temp_DeviceCust_Group AS grp WHERE TotalCust = 1);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Duplicate;
		CREATE TEMPORARY TABLE Temp_CustDevice_Duplicate LIKE Temp_CustDevice;
		INSERT INTO Temp_CustDevice_Duplicate 
		SELECT * FROM Temp_CustDevice;
        
        INSERT IGNORE INTO Temp_Association(CTSCustID, AssociationType)
		SELECT 	dv1.CTSCustID
			,	"Device"
		FROM Temp_CustDevice AS dv
			INNER JOIN Temp_CustDevice_Duplicate AS dv1 ON dv.DCSDeviceID = dv1.DCSDeviceID AND dv.CTSCustID != dv1.CTSCustID
		WHERE dv.CTSCustID = ip_CTSCustID;
     
        /*---------------------------------------------Get Association Manual --------------------------------------- */
		INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  cus.CTSCustID
			, 	ma.ToCTSCustID
			,  	"Manual" AS AssociationType
		FROM Temp_Cust AS cus 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID;
		
		INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  cus.CTSCustID
			, 	ma.FromCTSCustID
			,  	"Manual" AS AssociationType
		FROM Temp_Cust AS cus 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID;
		
        /*----------------------------------------------Get association by AI-------------------------------------------*/
		INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  tmp.CTSCustID
			, 	cus.CTSCustID
			,  	"Betting Pattern" AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.ToCustID = cus.CustID AND cus.CustSubID = 0;
		
		INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  tmp.CTSCustID
			, 	cus.CTSCustID
			,  	"Betting Pattern" AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ai.FromCustID = cus.CustID AND cus.CustSubID = 0;
	
        /*----------------------------------------------Get AssociationGroupByAI-------------------------------------------*/
		INSERT IGNORE INTO Temp_CustAIGroup(CTSCustID, GroupID)
		SELECT 	cus.CTSCustID 
			, 	asg.GroupID
		FROM Temp_Cust AS cus
			INNER JOIN  CTS_DataCenter.AssociationGroupByAI AS asg  ON asg.CustID = cus.CustID;
        
        INSERT INTO Temp_AIGroup_Level0(GroupID)
		SELECT 	DISTINCT
				GroupID
		FROM Temp_CustAIGroup;
        
        INSERT IGNORE INTO Temp_CustAIGroup_Level1(CTSCustID,GroupID)
		SELECT  cus.CTSCustID
			,	grp.GroupID
		FROM Temp_AIGroup_Level0 AS grp
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS lv1 ON grp.GroupID =  lv1.GroupID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CustID = cus.CustID AND cus.CustSubID = 0;
        
        INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT 	cuDv.CTSCustID
			, 	lv1.CTSCustID
			,	"Betting Pattern" AS AssociationType
		FROM Temp_CustAIGroup AS cuDv
			INNER JOIN Temp_CustAIGroup_Level1 AS lv1 ON cuDv.GroupID =  lv1.GroupID;
		
        INSERT INTO Temp_AIGroupCust_Group(GroupID, TotalCust)
		SELECT 	GroupID
			, 	COUNT(1) AS TotalCust
		FROM Temp_CustAIGroup 
		GROUP BY GroupID;
        
        DELETE FROM Temp_CustAIGroup AS tmp
		WHERE tmp.GroupID IN (SELECT grp.GroupID FROM Temp_AIGroupCust_Group AS grp WHERE TotalCust = 1);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_CustAIGroup_Duplicate;
		CREATE TEMPORARY TABLE Temp_CustAIGroup_Duplicate LIKE Temp_CustAIGroup;
		INSERT INTO Temp_CustAIGroup_Duplicate 
		SELECT * FROM Temp_CustAIGroup;
        
        INSERT IGNORE INTO Temp_Association(CTSCustID, AssociationType)
		SELECT 	grp1.CTSCustID
			,	"Betting Pattern"
		FROM Temp_CustAIGroup AS grp
			INNER JOIN Temp_CustAIGroup_Duplicate AS grp1 ON grp.GroupID = grp1.GroupID AND grp.CTSCustID != grp1.CTSCustID
		WHERE grp.CTSCustID = ip_CTSCustID;
       
        /*------------------------------------------Get association by IP-------------------------------------------------*/
		INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  tmp.CTSCustID
			, 	cus.CTSCustID
			,  	"IP" AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.ToCustID = cus.CustID AND cus.CustSubID = 0;
		
		INSERT IGNORE INTO Temp_Association_Level1(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  tmp.CTSCustID
			, 	cus.CTSCustID
			,  	"IP" AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID
            INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ip.FromCustID = cus.CustID AND cus.CustSubID = 0;
		
        /*------------------------------------------Result-------------------------------------------------*/
        INSERT IGNORE Temp_Association_Level1_Distinct(CTSCustID,CTSCustID_Level1)
		SELECT 	DISTINCT
				CTSCustID
			,  	CTSCustID_Level1
		FROM Temp_Association_Level1; 
        
		INSERT IGNORE INTO Temp_Association(CTSCustID, AssociationType)
		SELECT 	lv1.CTSCustID_Level1  
			, 	lv1.AssociationType 
		FROM Temp_Cust AS cus 
			INNER JOIN Temp_Association_Level1 AS lv1 ON lv1.CTSCustID = cus.CTSCustID AND lv1.CTSCustID_Level1 != ip_CTSCustID
		WHERE  cus.CTSCustID = ip_CTSCustID
			AND EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS dup WHERE lv1.CTSCustID_Level1 = dup.CTSCustID);
		
        INSERT IGNORE INTO Temp_Association(CTSCustID, AssociationType)
		SELECT 	lv1.CTSCustID  
			, 	lv1.AssociationType 
		FROM Temp_Cust AS cus 
			INNER JOIN Temp_Association_Level1 AS lv1 ON lv1.CTSCustID_Level1 = cus.CTSCustID AND lv1.CTSCustID != ip_CTSCustID
		WHERE  cus.CTSCustID = ip_CTSCustID
			AND EXISTS (SELECT 1 FROM Temp_Cust_Duplicate AS dup WHERE dup.CTSCustID = lv1.CTSCustID);
        
        INSERT INTO Temp_Level1_Group(CTSCustID, TotalCust)
		SELECT 	CTSCustID_Level1
			, 	COUNT(1) AS TotalCust
		FROM Temp_Association_Level1_Distinct 
		GROUP BY CTSCustID_Level1;
        
        DELETE
		FROM Temp_Association_Level1_Distinct AS tmp
		WHERE tmp.CTSCustID_Level1 IN (SELECT grp.CTSCustID FROM Temp_Level1_Group AS grp WHERE TotalCust = 1);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Distinct_Duplicate;
		CREATE TEMPORARY TABLE Temp_Association_Level1_Distinct_Duplicate LIKE Temp_Association_Level1_Distinct;
		INSERT INTO Temp_Association_Level1_Distinct_Duplicate 
		SELECT * FROM Temp_Association_Level1_Distinct;
        
        INSERT IGNORE INTO Temp_Association_Level2(CTSCustID)
		SELECT 	lv2.CTSCustID  
		FROM Temp_Association_Level1_Distinct AS lv1
			INNER JOIN Temp_Association_Level1_Distinct_Duplicate AS lv2 ON lv1.CTSCustID_Level1 = lv2.CTSCustID_Level1 AND lv2.CTSCustID != ip_CTSCustID
		WHERE lv1.CTSCustID = ip_CTSCustID
			AND NOT EXISTS (SELECT 1 FROM Temp_Association AS tmp WHERE tmp.CTSCustID = lv2.CTSCustID);
        
        INSERT IGNORE INTO Temp_Association(CTSCustID, AssociationType)
        SELECT 	CTSCustID
			,	"" AS AssociationType
        FROM Temp_Association_Level2;
    END IF;
    
    IF ip_HasAgent = 1 THEN
		INSERT IGNORE INTO Temp_CustDevice_Agent(CTSCustID, DCSDeviceID)
		SELECT 	cus.CTSCustID 
			, 	dv.DCSDeviceID
		FROM Temp_Recommend AS cus
			INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;
        
        INSERT INTO Temp_Device_Level0_Agent(DCSDeviceID)
		SELECT 	DISTINCT
				DCSDeviceID
		FROM Temp_CustDevice_Agent;
        
        INSERT IGNORE INTO Temp_CustDevice_Level1_Agent(CTSCustID,DCSDeviceID)
		SELECT  lv1.CTSCustID
			,	dv.DCSDeviceID
		FROM Temp_Device_Level0_Agent AS dv
			INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON dv.DCSDeviceID =  lv1.DCSDeviceID
		WHERE  NOT EXISTS (SELECT 1 FROM Temp_Recommend AS cus WHERE lv1.CTSCustID =  cus.CTSCustID);
        
        INSERT IGNORE INTO Temp_Association_Level1_Agent(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT 	cuDv.CTSCustID
			, 	lv1.CTSCustID
			,	"Device" AS AssociationType
		FROM Temp_CustDevice_Agent AS cuDv
			INNER JOIN Temp_CustDevice_Level1_Agent AS lv1 ON cuDv.DCSDeviceID =  lv1.DCSDeviceID;
		
        INSERT INTO Temp_DeviceCust_Group_Agent(DCSDeviceID, TotalCust)
		SELECT 	DCSDeviceID
			, 	COUNT(1) AS TotalCust
		FROM Temp_CustDevice_Agent 
		GROUP BY DCSDeviceID;
        
        DELETE FROM Temp_CustDevice_Agent AS tmp
		WHERE tmp.DCSDeviceID IN (SELECT grp.DCSDeviceID FROM Temp_DeviceCust_Group_Agent AS grp WHERE TotalCust = 1);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice_Agent_Duplicate;
		CREATE TEMPORARY TABLE Temp_CustDevice_Agent_Duplicate LIKE Temp_CustDevice_Agent;
		INSERT INTO Temp_CustDevice_Agent_Duplicate 
		SELECT * FROM Temp_CustDevice_Agent;
        
        INSERT IGNORE INTO Temp_Association_Agent(CTSCustID, AssociationType)
		SELECT 	dv1.CTSCustID
			,	"Device"
		FROM Temp_CustDevice_Agent AS dv
			INNER JOIN Temp_CustDevice_Agent_Duplicate AS dv1 ON dv.DCSDeviceID = dv1.DCSDeviceID AND dv.CTSCustID != dv1.CTSCustID
		WHERE dv.CTSCustID = lv_RecommendCTSCustID;
        
        
         /*---------------------------------------------Get Association Manual --------------------------------------- */
		INSERT IGNORE INTO Temp_Association_Level1_Agent(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  cus.CTSCustID
			, 	ma.ToCTSCustID
			,  	"Manual" AS AssociationType
		FROM Temp_Recommend AS cus 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID = cus.CTSCustID;
		
		INSERT IGNORE INTO Temp_Association_Level1_Agent(CTSCustID, CTSCustID_Level1, AssociationType)
		SELECT  cus.CTSCustID
			, 	ma.FromCTSCustID
			,  	"Manual" AS AssociationType
		FROM Temp_Recommend AS cus 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = cus.CTSCustID;
        
        ############
        /*------------------------------------------Result-------------------------------------------------*/
        INSERT IGNORE Temp_Association_Level1_Distinct_Agent(CTSCustID,CTSCustID_Level1)
		SELECT 	DISTINCT
				CTSCustID
			,  	CTSCustID_Level1
		FROM Temp_Association_Level1_Agent; 
        
		INSERT IGNORE INTO Temp_Association_Agent(CTSCustID, AssociationType)
		SELECT 	lv1.CTSCustID_Level1  
			, 	lv1.AssociationType 
		FROM Temp_Recommend AS cus 
			INNER JOIN Temp_Association_Level1_Agent AS lv1 ON lv1.CTSCustID = cus.CTSCustID AND lv1.CTSCustID_Level1 != ip_CTSCustID
		WHERE  cus.CTSCustID = lv_RecommendCTSCustID
			AND EXISTS (SELECT 1 FROM Temp_Recommend_Duplicate AS dup WHERE dup.CTSCustID = lv1.CTSCustID_Level1);
		
        INSERT IGNORE INTO Temp_Association_Agent(CTSCustID, AssociationType)
		SELECT 	lv1.CTSCustID  
			, 	lv1.AssociationType 
		FROM Temp_Recommend AS cus 
			INNER JOIN Temp_Association_Level1_Agent AS lv1 ON lv1.CTSCustID_Level1 = cus.CTSCustID AND lv1.CTSCustID != ip_CTSCustID
		WHERE  cus.CTSCustID = lv_RecommendCTSCustID
			AND EXISTS (SELECT 1 FROM Temp_Recommend_Duplicate AS dup WHERE dup.CTSCustID = lv1.CTSCustID);
        
        INSERT INTO Temp_Level1_Group_Agent(CTSCustID, TotalCust)
		SELECT 	CTSCustID_Level1
			, 	COUNT(1) AS TotalCust
		FROM Temp_Association_Level1_Distinct_Agent 
		GROUP BY CTSCustID_Level1;
        
        DELETE
		FROM Temp_Association_Level1_Distinct_Agent AS tmp
		WHERE tmp.CTSCustID_Level1 IN (SELECT grp.CTSCustID FROM Temp_Level1_Group_Agent AS grp WHERE TotalCust = 1);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1_Distinct_Agent_Duplicate;
		CREATE TEMPORARY TABLE Temp_Association_Level1_Distinct_Agent_Duplicate LIKE Temp_Association_Level1_Distinct_Agent;
		INSERT INTO Temp_Association_Level1_Distinct_Agent_Duplicate 
		SELECT * FROM Temp_Association_Level1_Distinct_Agent;
        
        INSERT IGNORE INTO Temp_Association_Level2_Agent(CTSCustID)
		SELECT 	lv2.CTSCustID  
		FROM Temp_Association_Level1_Distinct_Agent AS lv1
			INNER JOIN Temp_Association_Level1_Distinct_Agent_Duplicate AS lv2 ON lv1.CTSCustID_Level1 = lv2.CTSCustID_Level1 AND lv2.CTSCustID != lv_RecommendCTSCustID
		WHERE lv1.CTSCustID = lv_RecommendCTSCustID
			AND NOT EXISTS (SELECT 1 FROM Temp_Association_Agent AS tmp WHERE tmp.CTSCustID = lv2.CTSCustID);
        
        INSERT IGNORE INTO Temp_Association_Agent(CTSCustID, AssociationType)
        SELECT 	CTSCustID
			,	"" AS AssociationType
        FROM Temp_Association_Level2_Agent;
        
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
