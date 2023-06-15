/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_DetectGroup_Monitor`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_DetectGroup_Monitor`(
		IN	ip_CustIDs		LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN 
/*
	Created:	20230614@Victoria.Le
	Task :		
	DB:			
	
	Description: 

	Revisions:	
		- 20230614@Victoria.Le: 	Initial Writing [Redmine ID: #185793]
		
	Param's Explanation (filtered by):

	Example: CALL CTS_DataCenter.CTS_DC_AssociationDetection_DetectGroup_Monitor('3717173,3720243,3720262,3722388,55725774,55698841,65491199');
*/

	DECLARE	CONST_GROUP_NORMAL 				INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 			INT DEFAULT 0;
	
	DECLARE CONST_ASSTYPE_BETTINGPATTERN 	INT DEFAULT 2;
	DECLARE CONST_ASSTYPE_IP 				INT DEFAULT 4;
    
	DECLARE CONST_ASSBYAI_ACTIVESTATUS 		INT DEFAULT 1;	    
	DECLARE CONST_ASSBYIP_ACTIVESTATUS 		INT DEFAULT 1;

    DECLARE CONS_RangeDevice 				BIGINT DEFAULT 10000000000;
	DECLARE CONS_RangeAIGroup 				BIGINT DEFAULT 20000000000;
    DECLARE CONST_AGENT_RANGE				BIGINT DEFAULT 3000000000;
    
    DECLARE lv_OrigID 						BIGINT;
    DECLARE lv_GroupID 						BIGINT;
    DECLARE lv_Count1 						INT;

	/** Primary **************************/
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_AssType;
	CREATE TEMPORARY TABLE 	Temp_AssociationByAI_AssType (
			AssTypeItemValue 				INT PRIMARY KEY            
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_AssType;
	CREATE TEMPORARY TABLE 	Temp_AssociationByIP_AssType (
			AssTypeItemValue 				INT PRIMARY KEY            
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_Primary_CustNode;
	CREATE TEMPORARY TABLE 	Temp_Primary_CustNode (
			CTSCustID 						BIGINT  PRIMARY KEY 
		,	CustID   						BIGINT	
		,	INDEX IX_Temp_Primary_CustNode(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Primary_Graph;
    CREATE TEMPORARY TABLE 	Temp_Primary_Graph (
			OrigID 							BIGINT  
		,	DestID   						BIGINT
		,	AssociationType					SMALLINT 
		,	PRIMARY KEY(OrigID, DestID,AssociationType)
		,	INDEX IX_Temp_Primary_Graph(DestID)
	);
    
    INSERT INTO Temp_AssociationByAI_AssType(AssTypeItemValue)
	SELECT atd.AssTypeItemValue
	FROM CTS_DataCenter.AssociationTypeSetting AS atd
	WHERE atd.AssTypeID = CONST_ASSTYPE_BETTINGPATTERN AND atd.AssTypeItemStatus = CONST_ASSBYAI_ACTIVESTATUS; 
    
    INSERT INTO Temp_AssociationByIP_AssType(AssTypeItemValue)
    SELECT atd.AssTypeItemValue
    FROM CTS_DataCenter.AssociationTypeSetting AS atd
    WHERE atd.AssTypeID = CONST_ASSTYPE_IP AND atd.AssTypeItemStatus = CONST_ASSBYIP_ACTIVESTATUS; 
    
    INSERT IGNORE INTO Temp_Primary_CustNode(CTSCustID, CustID)
	SELECT 	DISTINCT
			cus.CTSCustID
		, 	cus.CustID
	FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.IsInternal = 0;
        
	-- 1. Device
    DROP TEMPORARY TABLE IF EXISTS Temp_Primary_Device;
	CREATE TEMPORARY TABLE Temp_Primary_Device (
			DCSDeviceID							BIGINT PRIMARY KEY 
	);
		
	INSERT INTO Temp_Primary_Device(DCSDeviceID)
	SELECT 	DISTINCT
			dv.DCSDeviceID 
	FROM Temp_Primary_CustNode AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;    
	
	INSERT IGNORE INTO Temp_Primary_Graph(OrigID,DestID,AssociationType)
	SELECT  cus.CTSCustID
		,	(CONS_RangeDevice + tmp.DCSDeviceID) AS DestID
		,	1 AS AssociationType 
	FROM Temp_Primary_Device AS tmp
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;

	-- 3. AI
    INSERT IGNORE INTO Temp_Primary_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
		,	3 AS AssociationType
	FROM Temp_Primary_CustNode AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID AND ai.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByAI_AssType AS tmpAt)
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;

	INSERT IGNORE INTO Temp_Primary_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
		,	3 AS AssociationType
	FROM Temp_Primary_CustNode AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID AND ai.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByAI_AssType AS tmpAt)
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;

	-- 4. Group AI
    DROP TEMPORARY TABLE IF EXISTS Temp_Primary_AIGroup;
	CREATE TEMPORARY TABLE 	Temp_Primary_AIGroup (
			GroupID								BIGINT  PRIMARY KEY
	);
	
	INSERT INTO Temp_Primary_AIGroup(GroupID)
	SELECT	DISTINCT
			asg.GroupID 
	FROM Temp_Primary_CustNode AS cus 
		INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON asg.CustID = cus.CustID;  
		
	INSERT IGNORE INTO Temp_Primary_Graph(OrigID,DestID,AssociationType)
	SELECT  cus.CTSCustID AS OrigID
		, 	(CONS_RangeAIGroup + tmp.GroupID) AS DestID
		,	4 AS AssociationType
	FROM Temp_Primary_AIGroup AS tmp 
		INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON tmp.GroupID = asg.GroupID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = asg.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
        
	-- 5. IP
    INSERT IGNORE INTO Temp_Primary_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
		,	5 AS AssociationType
	FROM Temp_Primary_CustNode AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID AND ip.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByIP_AssType AS tmpAt)
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
	INSERT IGNORE INTO Temp_Primary_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
		,	5 AS AssociationType
	FROM Temp_Primary_CustNode AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID AND ip.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByIP_AssType AS tmpAt)
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Primary_Graph_Dup;
	CREATE TEMPORARY TABLE Temp_Primary_Graph_Dup LIKE Temp_Primary_Graph;
	INSERT INTO Temp_Primary_Graph_Dup SELECT * FROM Temp_Primary_Graph;
    
    INSERT IGNORE INTO Temp_Primary_Graph(OrigID, DestID, AssociationType)
	SELECT 	DestID 
		,	OrigID
		,	AssociationType
	FROM Temp_Primary_Graph_Dup;

	/** Agent **************************/
    SET lv_GroupID = CONST_AGENT_RANGE;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Agent_Cust;
	CREATE TEMPORARY TABLE 	Temp_Agent_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
        ,	Recommend			BIGINT
		,	INDEX 				Temp_Agent_Cust(CustID)
        ,	INDEX 				Temp_Agent_Cust_Recommend(Recommend)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Agent_Recommend (
			CTSCustID 			BIGINT  PRIMARY KEY 
        ,	Recommend			BIGINT
        ,	Processed 			BIT DEFAULT 0
        ,	INDEX 				IX_Temp_Agent_Recommend_Recommend(Recommend)
        ,	INDEX				IX_Temp_Agent_Recommend_Processed(Processed)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_Agent_GroupResult (
			CTSCustID 			BIGINT PRIMARY KEY	
		,	GroupID 			BIGINT
		,	INDEX			    IX_Temp_Agent_GroupResult(GroupID)
	);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_GroupID;
	CREATE TEMPORARY TABLE 		Temp_Agent_GroupID (
			GroupID 			BIGINT PRIMARY KEY	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_NodeCTSCustID;
	CREATE TEMPORARY TABLE 		Temp_Agent_NodeCTSCustID (
			CTSCustID 			BIGINT PRIMARY KEY
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Agent_CustNode;
	CREATE TEMPORARY TABLE 	Temp_Agent_CustNode (
			CTSCustID 			BIGINT  PRIMARY KEY 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_Graph;
    CREATE TEMPORARY TABLE 	Temp_Agent_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
		,	AssociationType		SMALLINT 
		,	PRIMARY KEY(OrigID, DestID,AssociationType)
		,	INDEX IX_Temp_Agent_Graph(DestID)
	);
    
    INSERT IGNORE INTO Temp_Agent_Cust(CTSCustID, CustID, Recommend)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Recommend
	FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID 
														AND cus.IsInternal = 0
                                                        AND cus.RoleID = 1
                                                        AND cus.IsLicensee = 0;
                                                        
	INSERT IGNORE INTO Temp_Agent_Recommend(CTSCustID, Recommend)
	SELECT 	cus.CTSCustID
        ,	cus.CustID
	FROM Temp_Agent_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0;
                                                        
	INSERT IGNORE INTO Temp_Agent_CustNode(CTSCustID)
	SELECT DISTINCT CTSCustID
	FROM Temp_Agent_Recommend;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_Device;
	CREATE TEMPORARY TABLE 		Temp_Agent_Device (
			DCSDeviceID		BIGINT PRIMARY KEY 
	);
		
	INSERT INTO Temp_Agent_Device(DCSDeviceID)
	SELECT 	DISTINCT
			dv.DCSDeviceID 
	FROM Temp_Agent_CustNode AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;    
	
	INSERT IGNORE INTO Temp_Agent_Graph(OrigID,DestID,AssociationType)
	SELECT  cus.CTSCustID
		,	(CONS_RangeDevice + tmp.DCSDeviceID) AS DestID
		,	1 AS AssociationType 
	FROM Temp_Agent_Device AS tmp
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
	DROP TEMPORARY TABLE IF EXISTS Temp_Agent_Graph_Dup;
	CREATE TEMPORARY TABLE Temp_Agent_Graph_Dup LIKE Temp_Agent_Graph;
	INSERT INTO Temp_Agent_Graph_Dup SELECT * FROM Temp_Agent_Graph;
    
    INSERT IGNORE INTO Temp_Agent_Graph(OrigID, DestID, AssociationType)
	SELECT 	DestID 
		,	OrigID
		,	AssociationType
	FROM Temp_Agent_Graph_Dup;
        
	lp: LOOP 
		SET lv_OrigID = NULL;
        
        SELECT CTSCustID
        INTO lv_OrigID
		FROM Temp_Agent_Recommend
        WHERE Processed = 0
		LIMIT 1;

        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
        
		UPDATE Temp_Agent_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID;
    
		INSERT IGNORE INTO Temp_Agent_NodeCTSCustID(CTSCustID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT grp.OrigID 
				FROM Temp_Agent_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID
		) 
		SELECT cte.OrigID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_Agent_Recommend AS tmp WHERE tmp.CTSCustID = cte.OrigID);
        
        SELECT 	COUNT(1)
        INTO 	lv_Count1
        FROM Temp_Agent_NodeCTSCustID;
        
        IF lv_Count1 IS NULL OR lv_Count1 = 1 THEN
			TRUNCATE TABLE Temp_Agent_NodeCTSCustID;
        END IF;
        
        INSERT IGNORE INTO Temp_Agent_GroupID(GroupID)
        SELECT 	DISTINCT 
				gr.GroupID
        FROM Temp_Agent_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_Agent_NodeCTSCustID AS tmp WHERE gr.CTSCustID = tmp.CTSCustID);
		
        IF EXISTS (SELECT 1 FROM Temp_Agent_GroupID) THEN
			UPDATE Temp_Agent_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_Agent_GroupID AS tmp WHERE gr.GroupID = tmp.GroupID);
        END IF;
        
        INSERT IGNORE Temp_Agent_GroupResult(CTSCustID,GroupID)
        SELECT 	CTSCustID
            ,	lv_GroupID
        FROM Temp_Agent_NodeCTSCustID;
        
        UPDATE Temp_Agent_Recommend AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_Agent_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID);
        
		SET lv_GroupID = lv_GroupID + 1;
        TRUNCATE TABLE Temp_Agent_NodeCTSCustID;
        TRUNCATE TABLE Temp_Agent_GroupID;
	END LOOP;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent_Cust_GroupResult;
	CREATE TEMPORARY TABLE Temp_Agent_Cust_GroupResult (
			OrigID		BIGINT
		,	DestID		BIGINT		
    );
    
	INSERT INTO Temp_Agent_Cust_GroupResult
	SELECT 	cus.CTSCustID AS OrigID
		,	GroupID AS DestID
	FROM Temp_Agent_GroupResult AS grp
		INNER JOIN Temp_Agent_Recommend AS re ON re.CTSCustID = grp.CTSCustID
		INNER JOIN Temp_Agent_Cust AS cus ON re.Recommend = cus.Recommend;
    
	/** Detect Group **************************/
	DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_Cust;
	CREATE TEMPORARY TABLE 		Temp_DetectGroup_Cust (
			RowNumber		INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	CTSCustID		BIGINT UNSIGNED 
		,	CustID 			BIGINT UNSIGNED
        ,	Username		VARCHAR(50)
        ,	CustStatus		VARCHAR(50)
        ,	Recommend		BIGINT UNSIGNED
        ,	Danger1			TINYINT
        ,	Danger2			TINYINT
        ,	Danger3			TINYINT
        ,	Danger4			TINYINT
        ,	Danger5			TINYINT
        ,	RoleID			TINYINT
        ,	CreatedDate		DATETIME
        ,   IsLicensee      BIT 
        ,	Processed 		BIT DEFAULT 0
        ,	INDEX			IX_Temp_DetectGroup_Cust(CustID)
        ,	INDEX			IX_Temp_DetectGroup_Cust_Processed(Processed)
        ,	UNIQUE			IX_Temp_DetectGroup_Cust_CTSCustID(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_Cust_Dup;
	CREATE TEMPORARY TABLE 		Temp_DetectGroup_Cust_Dup (
			CTSCustID		BIGINT UNSIGNED  PRIMARY KEY
		,	CustID 			BIGINT UNSIGNED
        ,	INDEX			IX_Temp_DetectGroup_Cust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_Recommend;
	CREATE TEMPORARY TABLE 	Temp_DetectGroup_Recommend (
			CTSCustID  			BIGINT  UNSIGNED PRIMARY KEY 
        ,	CustID				BIGINT  UNSIGNED UNSIGNED
        ,	Username			VARCHAR(50)
        ,	Evidence			LONGTEXT
        ,	MemberCTSCustID		BIGINT
        ,	INDEX 				IX_Temp_DetectGroup_Recommend_MemberCTSCustID(MemberCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_CustAssociationType;
	CREATE TEMPORARY TABLE 		Temp_DetectGroup_CustAssociationType (
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
		,	AssociationType 	VARCHAR(100) DEFAULT ''
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_DestIDCount;
	CREATE TEMPORARY TABLE 	Temp_DetectGroup_DestIDCount (
			DestID 	BIGINT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_DetectGroup_GroupResult (
			CTSCustID 			BIGINT PRIMARY KEY	
		,	GroupID 			BIGINT
		,	INDEX			    IX_Temp_DetectGroup_GroupResult(GroupID)
	);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_GroupID;
	CREATE TEMPORARY TABLE 		Temp_DetectGroup_GroupID (
			GroupID 			BIGINT PRIMARY KEY	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_NodeCTSCustID;
	CREATE TEMPORARY TABLE 		Temp_DetectGroup_NodeCTSCustID (
			CTSCustID 			BIGINT PRIMARY KEY
	);
    

    # 1-Device, 3-AI, 4-AIGroup, 5-IP, 6 - Agent
    DROP TEMPORARY TABLE IF EXISTS Temp_DetectGroup_Graph;
	CREATE TEMPORARY TABLE 	Temp_DetectGroup_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
        ,	HasDevice			BIT DEFAULT 0
        ,	HasAI				BIT DEFAULT 0
        ,	HasAIGroup			BIT DEFAULT 0
        ,	HasIP				BIT DEFAULT 0
        ,	HasAgent			BIT DEFAULT 0
        ,	HasSharedIP			BIT DEFAULT 0
        ,	HasSharedMatches	BIT DEFAULT 0
		,	PRIMARY KEY(OrigID, DestID)
		,	INDEX IX_Temp_DetectGroup_Graph(DestID,OrigID)
	);
	
	SET lv_GroupID = 1;
	
	INSERT IGNORE INTO Temp_DetectGroup_Cust(CTSCustID, CustID,Username,CustStatus,Recommend,Danger1,Danger2,Danger3,Danger4,Danger5,RoleID,CreatedDate,Processed,IsLicensee)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Username
        ,	sta.ItemName AS CustStatus
        ,	cus.Recommend
        ,	cus.Danger1
        ,	cus.Danger2
        ,	cus.Danger3
        ,	cus.Danger4
        ,	cus.Danger5
        ,	cus.RoleID
        ,	cus.CreatedDate
        ,	CASE WHEN cus.CTSCustID IS NULL OR cus.IsInternal = 1 THEN 1
			ELSE 0 END AS Processed
        ,   cus.IsLicensee
	FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID  
        LEFT JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cus.CustStatusID;
		
	INSERT IGNORE INTO Temp_DetectGroup_Cust_Dup(CTSCustID, CustID)
    SELECT 	CTSCustID
		,	CustID
    FROM Temp_DetectGroup_Cust
    WHERE Processed = 0;

	INSERT IGNORE INTO Temp_DetectGroup_Recommend(CTSCustID,CustID,Username,Evidence,MemberCTSCustID)
    SELECT 	cus.CTSCustID
		,	cus.CustID
		,	cus.Username
        ,	(SELECT GROUP_CONCAT(DISTINCT ' ',ev.EvidenceCode) 
			 FROM CTS_DataCenter.CustEvidence AS ce  
				LEFT JOIN CTS_DataCenter.Evidence AS ev ON ev.EvidenceID = ce.EvidenceID
             WHERE cus.CTSCustID = ce.CTSCustID) AS Evidence
		,	tmp.CTSCustID
    FROM Temp_DetectGroup_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0
    WHERE tmp.RoleID = 1
        AND tmp.IsLicensee = 0;
		
	INSERT IGNORE INTO Temp_DetectGroup_Graph(OrigID,DestID, HasDevice, HasAI, HasAIGroup, HasIP)
    SELECT 	js.OrigID
		,	js.DestID
        ,	CASE WHEN AssociationType = 1 THEN 1 ELSE 0 END AS HasDevice
        ,	CASE WHEN AssociationType = 3 THEN 1 ELSE 0 END AS HasAI
        ,	CASE WHEN AssociationType = 4 THEN 1 ELSE 0 END AS HasAIGroup
        ,	CASE WHEN AssociationType = 5 THEN 1 ELSE 0 END AS HasIP
	FROM Temp_Primary_Graph AS js
    ON DUPLICATE KEY UPDATE HasDevice = CASE WHEN js.AssociationType = 1 THEN 1 ELSE HasDevice END
                        ,	HasAI = CASE WHEN js.AssociationType = 3 THEN 1 ELSE HasAI END
                        ,	HasAIGroup = CASE WHEN js.AssociationType = 4 THEN 1 ELSE HasAIGroup END
                        ,	HasIP = CASE WHEN js.AssociationType = 5 THEN 1 ELSE HasIP END;
						
	INSERT IGNORE INTO Temp_DetectGroup_Graph(OrigID,DestID,HasAgent) 
    SELECT 	OrigID
		,	DestID
        ,	1 AS HasAgent
	FROM Temp_Agent_Cust_GroupResult AS js
    ON DUPLICATE KEY UPDATE HasAgent = 1;
	
	INSERT IGNORE INTO Temp_DetectGroup_Graph(OrigID,DestID,HasAgent) 
    SELECT 	DestID
		,	OrigID
        ,	1 AS HasAgent
	FROM Temp_Agent_Cust_GroupResult AS js
    ON DUPLICATE KEY UPDATE HasAgent = 1;
	
	lp: LOOP 
		SET lv_OrigID = NULL;
        
        SELECT CTSCustID
        INTO lv_OrigID
		FROM Temp_DetectGroup_Cust
        WHERE Processed = 0
		LIMIT 1;
        
        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
        
        UPDATE Temp_DetectGroup_Cust AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID;
                         
		INSERT IGNORE INTO Temp_DetectGroup_NodeCTSCustID(CTSCustID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT grp.OrigID 
				FROM Temp_DetectGroup_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID
		) 
		SELECT OrigID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_DetectGroup_Cust AS tmp WHERE tmp.CTSCustID = cte.OrigID);
            
		SELECT 	COUNT(1)
        INTO 	lv_Count1
        FROM Temp_DetectGroup_NodeCTSCustID;
        
        IF lv_Count1 IS NULL OR lv_Count1 = 1 THEN
			TRUNCATE TABLE Temp_DetectGroup_NodeCTSCustID;
        END IF;
        
        INSERT IGNORE INTO Temp_DetectGroup_GroupID(GroupID)
        SELECT 	DISTINCT 
				gr.GroupID
        FROM Temp_DetectGroup_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_DetectGroup_NodeCTSCustID AS tmp WHERE gr.CTSCustID = tmp.CTSCustID);
        
        IF EXISTS (SELECT 1 FROM Temp_DetectGroup_GroupID) THEN
			UPDATE Temp_DetectGroup_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_DetectGroup_GroupID AS tmp WHERE gr.GroupID = tmp.GroupID);
        END IF;
        
        INSERT IGNORE Temp_DetectGroup_GroupResult(CTSCustID,GroupID)
        SELECT 	CTSCustID
            ,	lv_GroupID
        FROM Temp_DetectGroup_NodeCTSCustID;
        
        UPDATE Temp_DetectGroup_Cust AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_DetectGroup_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID);
        
        SET lv_GroupID = lv_GroupID + 1;
        TRUNCATE TABLE Temp_DetectGroup_NodeCTSCustID;
        TRUNCATE TABLE Temp_DetectGroup_GroupID;
	END LOOP;
	
	INSERT INTO Temp_DetectGroup_DestIDCount(DestID)
    SELECT grp.DestID
    FROM Temp_DetectGroup_Graph AS grp
    WHERE EXISTS (SELECT 1 FROM Temp_DetectGroup_Cust AS cus WHERE cus.CTSCustID = grp.OrigID AND (grp.HasDevice = 1 OR grp.HasAIGroup = 1 OR grp.HasAgent = 1 ))
    GROUP BY DestID
    HAVING COUNT(1) > 1;
	
	INSERT IGNORE INTO Temp_DetectGroup_CustAssociationType(CTSCustID, AssociationType)
    SELECT 	cus.CTSCustID
		,   'Device'
    FROM Temp_DetectGroup_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_DetectGroup_Graph AS grp 
					INNER JOIN Temp_DetectGroup_DestIDCount AS des ON grp.DestID = des.DestID
				  WHERE cus.CTSCustID = grp.OrigID AND grp.HasDevice = 1);
    
    INSERT IGNORE INTO Temp_DetectGroup_CustAssociationType(CTSCustID, AssociationType)
    SELECT 	cus.CTSCustID
		,   'Agent'
    FROM Temp_DetectGroup_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_DetectGroup_Graph AS grp 
				  WHERE cus.CTSCustID = grp.OrigID AND grp.HasAgent = 1)
	ON DUPLICATE KEY UPDATE AssociationType = CONCAT(AssociationType, ", Agent");
	
    INSERT IGNORE INTO Temp_DetectGroup_CustAssociationType(CTSCustID, AssociationType)
    WITH CTE AS (SELECT cus.CTSCustID
					,	CONCAT(IF(MAX(HasAI) =1, ", Betting Pattern","")
                              ,IF(MAX(HasIP) =1, ", IP","")) AS AssociationTypeStr
				FROM Temp_DetectGroup_Cust AS cus
					INNER JOIN Temp_DetectGroup_Graph AS grp ON cus.CTSCustID = grp.OrigID AND (grp.HasDevice = 0 OR grp.HasAIGroup = 0 OR grp.HasAgent = 0)
                    INNER JOIN Temp_DetectGroup_Cust_Dup AS dup ON dup.CTSCustID = grp.DestID
				GROUP BY cus.CTSCustID)
	SELECT CTE.CTSCustID
		,	SUBSTR(CTE.AssociationTypeStr, 2)
    FROM CTE
    ON DUPLICATE KEY UPDATE AssociationType = CONCAT(AssociationType, CTE.AssociationTypeStr);
    
	INSERT INTO Temp_DetectGroup_CustAssociationType(CTSCustID, AssociationType)
    SELECT 	cus.CTSCustID
		,   'Betting Pattern' 
    FROM Temp_DetectGroup_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_DetectGroup_Graph AS grp 
					INNER JOIN Temp_DetectGroup_DestIDCount AS des ON grp.DestID = des.DestID
				  WHERE cus.CTSCustID = grp.OrigID AND grp.HasAIGroup = 1)
	ON DUPLICATE KEY UPDATE AssociationType = CASE WHEN AssociationType LIKE '%Betting Pattern%' THEN AssociationType
												   ELSE CONCAT(AssociationType,', Betting Pattern') END;
END$$

DELIMITER ;