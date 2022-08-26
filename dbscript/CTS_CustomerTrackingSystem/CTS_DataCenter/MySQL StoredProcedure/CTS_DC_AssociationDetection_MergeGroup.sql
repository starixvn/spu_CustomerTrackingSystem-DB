/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_MergeGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_MergeGroup`(
		IN	ip_CTSCustIDs		LONGTEXT
    ,	IN	ip_Primary			JSON 
    ,	IN	ip_Agent 			JSON 
    ,	IN	ip_SharedIP			JSON 
    ,	IN	ip_SharedMatches 	JSON 
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
			- CALL CTS_DC_AssociationDetection_MergeGroup_xtest("1,2",'[{"F":1,"T":2,"AT":1}]','[{"F":1,"T":2,"AT":1}]','[{"F":1,"T":2,"AT":1}]','[{"F":1,"T":2,"AT":1}]' );
	*/
    DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
	DECLARE	CONST_GROUP_WRAPPER 				INT DEFAULT 100;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
        
    DECLARE	CONST_LICVIP_DANGEROUSCC 			INT DEFAULT 99;
    DECLARE	CONST_VVIPCC						INT DEFAULT 100;
    DECLARE	CONST_LICVIP_SUSPICIOUSCC			INT DEFAULT 101;
    DECLARE	CONST_LICBAPRIORITY					INT DEFAULT 90;
    DECLARE	CONST_LICBACC						INT DEFAULT 14;
    

    DECLARE lv_OrigID 		BIGINT;
    DECLARE lv_GroupId 		INT DEFAULT 1;

    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			RowNumber		INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	CTSCustID		BIGINT UNSIGNED 
		,	CustID 			BIGINT UNSIGNED
        ,	Username		VARCHAR(50)
        ,	CustStatus		VARCHAR(50)
        ,	CustomerClass 	INT
        ,	IsLicenseeVIP	BIT
        ,	IsLicenseeBA	BIT
        ,	Processed 		BIT DEFAULT 0
        ,	INDEX			IX_Temp_Cust(CustID)
        ,	INDEX			IX_Temp_Cust_Processed(Processed)
        ,	UNIQUE			IX_Temp_Cust_CTSCustID(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust_Dup;
	CREATE TEMPORARY TABLE 		Temp_Cust_Dup (
			CTSCustID		BIGINT UNSIGNED  PRIMARY KEY
		,	CustID 			BIGINT UNSIGNED
        ,	INDEX			IX_Temp_Cust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
	CREATE TEMPORARY TABLE 		Temp_CustomerClass (
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		,	CustomerClass 	INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociationType;
	CREATE TEMPORARY TABLE 		Temp_CustAssociationType (
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
		,	AssociationType 	VARCHAR(100) DEFAULT ''
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DestIDCount;
	CREATE TEMPORARY TABLE 	Temp_DestIDCount (
			DestID 	BIGINT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE 		Temp_Group (
			CTSCustID 			BIGINT PRIMARY KEY 
		,	GroupID 			INT
		,	INDEX			    IX_Temp_Group(GroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupCount;
	CREATE TEMPORARY TABLE 	Temp_GroupCount (
			ID  		INT AUTO_INCREMENT PRIMARY KEY
		,	GroupID 	INT
        ,	Total 		INT
		,	UNIQUE 	    IX_Temp_GroupCount(GroupID)
	);
    # 1-Device, 2-Manual, 3-AI, 4-AIGroup, 5-IP, 6 - Agent, 7 - SharedIP, 8 - SharedMatches
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
	CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
        ,	HasDevice			BIT DEFAULT 0
        ,	HasManual			BIT DEFAULT 0
        ,	HasAI				BIT DEFAULT 0
        ,	HasAIGroup			BIT DEFAULT 0
        ,	HasIP				BIT DEFAULT 0
        ,	HasAgent			BIT DEFAULT 0
        ,	HasSharedIP			BIT DEFAULT 0
        ,	HasSharedMatches	BIT DEFAULT 0
		,	PRIMARY KEY(OrigID, DestID)
		,	INDEX IX_Temp_Graph(DestID,OrigID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Primary;
	CREATE TEMPORARY TABLE 	Temp_Primary (
			FromCTSCustID 		BIGINT  
		,	ToCTSCustID   		BIGINT
        ,	AssociationType		SMALLINT # 1-Device, 2-Manual, 3-AI, 4-AIGroup, 5-IP, 6 - Agent, 7 - SharedIP, 8 - SharedMatches
		,	PRIMARY KEY(FromCTSCustID, ToCTSCustID, AssociationType)
		,	INDEX Temp_Primary(ToCTSCustID,FromCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Agent;
	CREATE TEMPORARY TABLE 	Temp_Agent (
			FromCTSCustID 		BIGINT  
		,	ToCTSCustID   		BIGINT
		,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
		,	INDEX Temp_Agent(ToCTSCustID,FromCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SharedIP;
	CREATE TEMPORARY TABLE 	Temp_SharedIP (
			FromCTSCustID 		BIGINT  
		,	ToCTSCustID   		BIGINT
		,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
		,	INDEX Temp_SharedIP(ToCTSCustID,FromCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SharedMatches;
	CREATE TEMPORARY TABLE 	Temp_SharedMatches (
			FromCTSCustID 		BIGINT  
		,	ToCTSCustID   		BIGINT
		,	PRIMARY KEY(FromCTSCustID, ToCTSCustID)
		,	INDEX Temp_SharedMatches(ToCTSCustID,FromCTSCustID)
	);
    /*****************************Extract Data From Input**************************************************/
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID,Username,CustStatus,IsLicenseeVIP,IsLicenseeBA,CustomerClass,Processed)
	SELECT 	tmp.CTSCustID
		, 	cus.CustID
        ,	cus.Username
        ,	sta.ItemName AS CustStatus
        ,	cus.IsLicenseeVIP
        ,	cus.IsLicenseeBA
        ,	sp.CustomerClass
        ,	CASE WHEN cus.CTSCustID IS NULL OR cus.IsInternal = 1 THEN 1
			ELSE 0 END AS Processed
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID  
        LEFT JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cus.CustStatusID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = cus.CustID;
    
    INSERT IGNORE INTO Temp_Cust_Dup(CTSCustID, CustID)
    SELECT 	CTSCustID
		,	CustID
    FROM Temp_Cust
    WHERE Processed = 0;
    
    INSERT IGNORE INTO Temp_Primary(FromCTSCustID, ToCTSCustID,AssociationType)
	SELECT	js.FromCTSCustID
		,	js.ToCTSCustID
		,	js.AssociationType
	FROM JSON_TABLE(ip_Primary,
		"$[*]" COLUMNS( FromCTSCustID 		BIGINT 		PATH "$.F"                
					,	ToCTSCustID			BIGINT 		PATH "$.T"
					,	AssociationType		INT			PATH "$.A"
	)) AS js;
    
    INSERT IGNORE INTO Temp_Agent(FromCTSCustID, ToCTSCustID)
	SELECT	js.FromCTSCustID
		,	js.ToCTSCustID
	FROM JSON_TABLE(ip_Agent,
		"$[*]" COLUMNS( FromCTSCustID 		BIGINT 		PATH "$.F"                
					,	ToCTSCustID			BIGINT 		PATH "$.T"
	)) AS js;
    
    INSERT IGNORE INTO Temp_SharedIP(FromCTSCustID, ToCTSCustID)
	SELECT	js.FromCTSCustID
		,	js.ToCTSCustID
	FROM JSON_TABLE(ip_SharedIP,
		"$[*]" COLUMNS( FromCTSCustID 		BIGINT 		PATH "$.F"                
					,	ToCTSCustID			BIGINT 		PATH "$.T"
	)) AS js;
    
    INSERT IGNORE INTO Temp_SharedMatches(FromCTSCustID, ToCTSCustID)
	SELECT	js.FromCTSCustID
		,	js.ToCTSCustID
	FROM JSON_TABLE(ip_SharedMatches,
		"$[*]" COLUMNS( FromCTSCustID 		BIGINT 		PATH "$.F"                
					,	ToCTSCustID			BIGINT 		PATH "$.T"
	)) AS js;
    
    /*****************************Build Graph Struct**************************************************/
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID, HasDevice, HasManual, HasAI, HasAIGroup, HasIP)
    SELECT 	FromCTSCustID
		,	ToCTSCustID
        ,	CASE WHEN AssociationType = 1 THEN 1 ELSE 0 END AS HasDevice
        ,	CASE WHEN AssociationType = 2 THEN 1 ELSE 0 END AS HasManual
        ,	CASE WHEN AssociationType = 3 THEN 1 ELSE 0 END AS HasAI
        ,	CASE WHEN AssociationType = 4 THEN 1 ELSE 0 END AS HasAIGroup
        ,	CASE WHEN AssociationType = 5 THEN 1 ELSE 0 END AS HasIP
	FROM Temp_Primary AS tmp
    ON DUPLICATE KEY UPDATE HasDevice = CASE WHEN tmp.AssociationType = 1 THEN 1 ELSE HasDevice END
						,	HasManual = CASE WHEN tmp.AssociationType = 2 THEN 1 ELSE HasManual END
                        ,	HasAI = CASE WHEN tmp.AssociationType = 3 THEN 1 ELSE HasAI END
                        ,	HasAIGroup = CASE WHEN tmp.AssociationType = 4 THEN 1 ELSE HasAIGroup END
                        ,	HasIP = CASE WHEN tmp.AssociationType = 5 THEN 1 ELSE HasIP END;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasAgent) 
    SELECT 	FromCTSCustID
		,	ToCTSCustID
        ,	1 AS HasAgent
	FROM Temp_Agent
    ON DUPLICATE KEY UPDATE HasAgent = 1;
    
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedIP)  
    SELECT 	FromCTSCustID
		,	ToCTSCustID
        ,	1 AS HasSharedIP
	FROM Temp_SharedIP
    ON DUPLICATE KEY UPDATE HasSharedIP = 1;
    
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedMatches)  
    SELECT 	FromCTSCustID
		,	ToCTSCustID
        ,	1 AS HasSharedMatches
	FROM Temp_SharedMatches
    ON DUPLICATE KEY UPDATE HasSharedMatches = 1;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID, HasDevice, HasManual, HasAI, HasAIGroup, HasIP)
    SELECT 	ToCTSCustID
		,	FromCTSCustID
        ,	CASE WHEN AssociationType = 1 THEN 1 ELSE 0 END AS HasDevice
        ,	CASE WHEN AssociationType = 2 THEN 1 ELSE 0 END AS HasManual
        ,	CASE WHEN AssociationType = 3 THEN 1 ELSE 0 END AS HasAI
        ,	CASE WHEN AssociationType = 4 THEN 1 ELSE 0 END AS HasAIGroup
        ,	CASE WHEN AssociationType = 5 THEN 1 ELSE 0 END AS HasIP
	FROM Temp_Primary AS tmp
	ON DUPLICATE KEY UPDATE HasDevice = CASE WHEN tmp.AssociationType = 1 THEN 1 ELSE HasDevice END
						,	HasManual = CASE WHEN tmp.AssociationType = 2 THEN 1 ELSE HasManual END
                        ,	HasAI = CASE WHEN tmp.AssociationType = 3 THEN 1 ELSE HasAI END
                        ,	HasAIGroup = CASE WHEN tmp.AssociationType = 4 THEN 1 ELSE HasAIGroup END
                        ,	HasIP = CASE WHEN tmp.AssociationType = 5 THEN 1 ELSE HasIP END;
    
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasAgent) 
    SELECT 	ToCTSCustID 
		,	FromCTSCustID
        ,	1 AS HasAgent
	FROM Temp_Agent
    ON DUPLICATE KEY UPDATE HasAgent = 1;
    
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedIP)  
    SELECT 	ToCTSCustID 
		,	FromCTSCustID
        ,	1 AS HasSharedIP
	FROM Temp_SharedIP
    ON DUPLICATE KEY UPDATE HasSharedIP = 1;
    
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedMatches)  
    SELECT 	ToCTSCustID 
		,	FromCTSCustID
        ,	1 AS HasSharedMatches
	FROM Temp_SharedMatches
    ON DUPLICATE KEY UPDATE HasSharedMatches = 1;
    

    /*****************************Merge Group**************************************************/
	UPDATE  Temp_Cust AS cus 
    SET Processed = 1
	WHERE NOT EXISTS (SELECT 1 FROM Temp_Graph AS tmp WHERE tmp.OrigID = cus.CTSCustID);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GraphIDSingle;
	CREATE TEMPORARY TABLE 	Temp_GraphIDSingle (
			ID 				BIGINT   PRIMARY KEY
	);
    
	INSERT INTO Temp_GraphIDSingle(ID)
	SELECT OrigID
	FROM Temp_Graph 
	WHERE OrigID < 0
	GROUP BY OrigID
	HAVING COUNT(1) = 1;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GrapCustIDSingle;
	CREATE TEMPORARY TABLE 	Temp_GrapCustIDSingle (
			CTSCustID 			BIGINT   PRIMARY KEY
	);
    
    INSERT INTO Temp_GrapCustIDSingle(CTSCustID)
	SELECT 	DISTINCT
			cus.CTSCustID
	FROM Temp_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_Graph AS  grp 
					INNER JOIN Temp_GraphIDSingle as tmp on grp.DestID = tmp.ID
				  WHERE cus.CTSCustID  = grp.OrigID);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_GrapCustIDAlone;
	CREATE TEMPORARY TABLE 	Temp_GrapCustIDAlone (
			CTSCustID 			BIGINT   PRIMARY KEY
	);
    
    INSERT INTO Temp_GrapCustIDAlone(CTSCustID)
    SELECT tmp.CTSCustID
	FROM Temp_GrapCustIDSingle as tmp
	WHERE NOT EXISTS (SELECT 1 FROM  Temp_Graph AS  grp WHERE tmp.CTSCustID  = grp.OrigID AND  grp.DestID > 0);
    
	UPDATE  Temp_Cust AS cus 
    SET Processed = 1
	WHERE  EXISTS (SELECT 1 FROM Temp_GrapCustIDAlone AS tmp WHERE tmp.CTSCustID = cus.CTSCustID);
    
    lp: LOOP 
		SET lv_OrigID = NULL;
        
        SELECT CTSCustID
        INTO lv_OrigID
		FROM Temp_Cust
        WHERE Processed = 0
		LIMIT 1;
        
        IF lv_OrigID IS NULL 
        THEN 
            LEAVE lp; 
        END IF;
                         
		INSERT IGNORE INTO Temp_Group(CTSCustID,GroupID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT grp.OrigID 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID
		) 
		SELECT OrigID
			,  lv_GroupId 
        FROM CTE_Group;
        
        UPDATE Temp_Cust AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID
			OR EXISTS (SELECT 1 FROM Temp_Group AS gp WHERE  gp.CTSCustID = tmp.CTSCustID);
            
		SET lv_GroupId = lv_GroupId + 1;
	END LOOP;

    DELETE 
	FROM Temp_Group AS grp
	WHERE NOT EXISTS (SELECT 1 FROM Temp_Cust AS tmp WHERE grp.CTSCustID = tmp.CTSCustID);
    
    INSERT INTO Temp_GroupCount(GroupID, Total)
    SELECT 	GroupID
		,	COUNT(1)
    FROM Temp_Group
    GROUP BY GroupID
    ORDER BY COUNT(1) DESC;
    
    DELETE 
	FROM Temp_Group AS grp
	WHERE EXISTS (SELECT 1 FROM Temp_GroupCount AS tmp WHERE grp.GroupID = tmp.GroupID AND Total = 1);


    UPDATE Temp_Group AS grp
    INNER JOIN Temp_GroupCount AS tmp ON grp.GroupID = tmp.GroupID
    SET grp.GroupID = tmp.ID;
    
    /*****************************Handle AssociationType Info**************************************************/
    INSERT INTO Temp_DestIDCount(DestID)
    SELECT grp.DestID
    FROM Temp_Graph AS grp
    WHERE EXISTS (SELECT 1 FROM Temp_Cust AS cus WHERE cus.CTSCustID = grp.OrigID AND (grp.HasDevice = 1 OR grp.HasAIGroup = 1 OR grp.HasAgent = 1 ))
    GROUP BY DestID
    HAVING COUNT(1) > 1;
    
    INSERT IGNORE INTO Temp_CustAssociationType(CTSCustID, AssociationType)
    SELECT 	cus.CTSCustID
		,   'Device'
    FROM Temp_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_Graph AS grp 
					INNER JOIN Temp_DestIDCount AS des ON grp.DestID = des.DestID
				  WHERE cus.CTSCustID = grp.OrigID AND grp.HasDevice = 1);
	
    INSERT IGNORE INTO Temp_CustAssociationType(CTSCustID, AssociationType)
    SELECT 	cus.CTSCustID
		,   'Agent'
    FROM Temp_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_Graph AS grp 
				  WHERE cus.CTSCustID = grp.OrigID AND grp.HasAgent = 1)
	ON DUPLICATE KEY UPDATE AssociationType = CONCAT(AssociationType, ", Agent");
	
    INSERT IGNORE INTO Temp_CustAssociationType(CTSCustID, AssociationType)
    WITH CTE AS (SELECT cus.CTSCustID
					,	CONCAT(IF(MAX(HasManual) =1, ", Manual","")
                              ,IF(MAX(HasAI) =1, ", Betting Pattern","")
                              ,IF(MAX(HasIP) =1, ", IP","")
                              ,IF(MAX(HasSharedIP) =1, ", IP(last3days)","")
                              ,IF(MAX(HasSharedMatches) =1, ", Match","")) AS AssociationTypeStr
				FROM Temp_Cust AS cus
					INNER JOIN Temp_Graph AS grp ON cus.CTSCustID = grp.OrigID AND (grp.HasDevice = 0 OR grp.HasAIGroup = 0 OR grp.HasAgent = 0)
                    INNER JOIN Temp_Cust_Dup AS dup ON dup.CTSCustID = grp.DestID
				GROUP BY cus.CTSCustID)
	SELECT CTE.CTSCustID
		,	SUBSTR(CTE.AssociationTypeStr, 2)
    FROM CTE
    ON DUPLICATE KEY UPDATE AssociationType = CONCAT(AssociationType, CTE.AssociationTypeStr);
    
    INSERT INTO Temp_CustAssociationType(CTSCustID, AssociationType)
    SELECT 	cus.CTSCustID
		,   'Betting Pattern' 
    FROM Temp_Cust AS cus
    WHERE EXISTS (SELECT 1 
				  FROM Temp_Graph AS grp 
					INNER JOIN Temp_DestIDCount AS des ON grp.DestID = des.DestID
				  WHERE cus.CTSCustID = grp.OrigID AND grp.HasAIGroup = 1)
	ON DUPLICATE KEY UPDATE AssociationType = CASE WHEN AssociationType LIKE '%Betting Pattern%' THEN AssociationType
												   ELSE CONCAT(AssociationType,', Betting Pattern') END;
    
    /*****************************Handle CustomerClass Info**************************************************/
    INSERT INTO Temp_CustomerClass(CTSCustID,CustomerClass)
    SELECT 	tmp.CTSCustID
		,	clss.CustomerClass
    FROM Temp_Cust AS tmp,
		LATERAL(SELECT CASE WHEN tmp.CustomerClass IS NULL THEN CASE WHEN cate.CustomerClass = CONST_VVIPCC THEN CONST_VVIPCC
																	 WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN CONST_LICVIP_SUSPICIOUSCC
																	 WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN CONST_LICVIP_DANGEROUSCC
																	 WHEN tmp.IsLicenseeBA = 1 AND cate.Priority > CONST_LICBAPRIORITY THEN CONST_LICBACC
																	 ELSE cate.CustomerClass END
						ELSE tmp.CustomerClass END AS CustomerClass
				FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID
                WHERE clss.CustID = tmp.CustID
					AND clss.SportGroupID IN (CONST_GROUP_PROBLEM, CONST_GROUP_WRAPPER,CONST_GROUP_NORMAL)
                ORDER BY  cate.Priority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss;
    
    SELECT 	cus.RowNumber 
		,	grp.GroupID
		,	cus.CTSCustID
        ,	cus.CustID
        ,	cus.Username
        ,	cus.CustStatus
        ,	asTy.AssociationType
        
        ,	(SELECT GROUP_CONCAT(DISTINCT ' ',ev.EvidenceCode) 
			 FROM CTS_DataCenter.CustEvidence AS ce  
             LEFT JOIN CTS_DataCenter.Evidence AS ev ON ev.EvidenceID = ce.EvidenceID
             WHERE cus.CTSCustID = ce.CTSCustID) AS Evidence
        
        , 	TRIM(GROUP_CONCAT(DISTINCT ' ',cat.CategoryName)) AS CustomerCategory
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.CategoryID)) AS CategoryIDs
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.ParentID)) AS ParentIDs
        ,   MAX(cat.IsPAProbation) AS IsPAProbation
        
        ,	cusclss.CustomerClass
    FROM Temp_Cust AS cus
		LEFT JOIN Temp_Group AS grp ON cus.CTSCustID = grp.CTSCustID
        LEFT JOIN Temp_CustomerClass AS cusclss ON cus.CTSCustID = cusclss.CTSCustID
        LEFT JOIN  Temp_CustAssociationType AS asTy ON cus.CTSCustID = asTy.CTSCustID
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON cus.CustID = clss.CustID AND  clss.SportGroupID IN (CONST_GROUP_PROBLEM, CONST_GROUP_NORMAL)
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = clss.CategoryID
	GROUP BY cus.RowNumber 
		,	grp.GroupID
		,	cus.CTSCustID
        ,	cus.CustID
        ,	cus.Username
        ,	cus.CustStatus
        ,	cusclss.CustomerClass;
	
END$$

DELIMITER ;
