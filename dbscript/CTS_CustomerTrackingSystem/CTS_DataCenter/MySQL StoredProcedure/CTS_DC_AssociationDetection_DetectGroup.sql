/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_DetectGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_DetectGroup`(
		IN	ip_CTSCustIDs		LONGTEXT
    ,	IN	ip_Primary			JSON 
    ,	IN	ip_Agent 			JSON 
    ,	IN	ip_SharedIP			JSON 
    ,	IN	ip_SharedMatches 	JSON 
    , 	IN	ip_IsGetLogTransInfo BOOLEAN
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*  
		Created:	20220727@Aries.Nguyen
		Task:		[CTS] Enhance Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20220727@Aries.Nguyen: Created [Redmine ID: #175701]
            - 20220907@Aries.Nguyen: CTS - Association Detection - Display in correct CC [Redmine ID: #177559]
            - 20220930@Aries.Nguyen: Renovate Association Detection [RedmineID: #178311]
            - 20221101@Aries.Nguyen: Return IsLicensee value [RedmineID: #178311]
            - 20221107@Aries.Nguyen: Missing Agent info [RedmineID: #180181]
            - 20221205@Aries.Nguyen: Re-arrange type options on Association Detection  [Redmine ID: #181207]
			- 20231116@Thomas.Nguyen: Return more Log Transaction info on Association Detection  [Redmine ID: #196362]
            
		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DC_AssociationDetection_DetectGroup("17,18,20,22",'[{"O":11111,"D":17,"A":1},{"O":11111,"D":18,"A":1},{"O":17,"D":11111,"A":1},{"O":18,"D":11111,"A":1}]','[{"O":20,"D":1},{"O":22,"D":1}]','[{"O":20,"D":22}]','[{"O":20,"D":22}]');
	*/
    DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
    
    DECLARE lv_OrigID 		BIGINT;
    DECLARE lv_GroupID 		BIGINT DEFAULT 1;
    DECLARE lv_CustIDs 		LONGTEXT;
    DECLARE lv_Count1 		INT;
    DECLARE lv_FromDate		DATE;
	DECLARE lv_ToDate		DATE;
    DECLARE lv_SubSourceID_DirectAPI		TINYINT DEFAULT(1);
	DECLARE lv_SubSourceID_OddsFeed			TINYINT DEFAULT(2);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
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
        ,	SubscriberID	INT
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Recommend (
			CTSCustID  			BIGINT  UNSIGNED PRIMARY KEY 
        ,	CustID				BIGINT  UNSIGNED UNSIGNED
        ,	Username			VARCHAR(50)
        ,	Evidence			LONGTEXT
        ,	MemberCTSCustID		BIGINT
        ,	INDEX 				IX_Temp_Recommend_MemberCTSCustID(MemberCTSCustID)
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupResult;
	CREATE TEMPORARY TABLE 		Temp_GroupResult (
			CTSCustID 			BIGINT PRIMARY KEY	
		,	GroupID 			BIGINT
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
    

    # 1-Device, 2-Manual, 3-AI, 4-AIGroup, 5-IP, 6 - Agent, 7 - SharedIP, 8 - SharedMatches
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
	CREATE TEMPORARY TABLE 	Temp_Graph (
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
		,	INDEX IX_Temp_Graph(DestID,OrigID)
	);
 
	DROP TEMPORARY TABLE IF EXISTS Temp_CustLogTransInfo;
	CREATE TEMPORARY TABLE 		Temp_CustLogTransInfo (
			CTSCustID 						BIGINT UNSIGNED PRIMARY KEY
		,	CountLogin						INT DEFAULT 0
        ,	CountBotTrans					INT DEFAULT 0
        ,	CountInvalidBrowserTrans		INT DEFAULT 0
	);
    
    /*****************************Extract Data From Input**************************************************/
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID,Username,CustStatus,Recommend,Danger1,Danger2,Danger3,Danger4,Danger5,RoleID,CreatedDate,Processed,IsLicensee)
	SELECT 	tmp.CTSCustID
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
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID  
        LEFT JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cus.CustStatusID;   

    INSERT IGNORE INTO Temp_Cust_Dup(CTSCustID, CustID)
    SELECT 	CTSCustID
		,	CustID
    FROM Temp_Cust
    WHERE Processed = 0;
    
    INSERT IGNORE INTO Temp_Recommend(CTSCustID,CustID,Username,Evidence,MemberCTSCustID)
    SELECT 	cus.CTSCustID
		,	cus.CustID
		,	cus.Username
        ,	(SELECT GROUP_CONCAT(DISTINCT ' ',ev.EvidenceCode) 
			 FROM CTS_DataCenter.CustEvidence AS ce  
				LEFT JOIN CTS_DataCenter.Evidence AS ev ON ev.EvidenceID = ce.EvidenceID
             WHERE cus.CTSCustID = ce.CTSCustID) AS Evidence
		,	tmp.CTSCustID
    FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0
    WHERE tmp.RoleID = 1
        AND tmp.IsLicensee = 0;

	INSERT IGNORE INTO Temp_Graph(OrigID,DestID, HasDevice, HasAI, HasAIGroup, HasIP)
    SELECT 	js.OrigID
		,	js.DestID
        ,	CASE WHEN AssociationType = 1 THEN 1 ELSE 0 END AS HasDevice
        ,	CASE WHEN AssociationType = 3 THEN 1 ELSE 0 END AS HasAI
        ,	CASE WHEN AssociationType = 4 THEN 1 ELSE 0 END AS HasAIGroup
        ,	CASE WHEN AssociationType = 5 THEN 1 ELSE 0 END AS HasIP
	FROM JSON_TABLE(ip_Primary,
		"$[*]" COLUMNS( OrigID 				BIGINT 		PATH "$.O"                
					,	DestID				BIGINT 		PATH "$.D"
					,	AssociationType		INT			PATH "$.A"
	)) AS js
    ON DUPLICATE KEY UPDATE HasDevice = CASE WHEN js.AssociationType = 1 THEN 1 ELSE HasDevice END
                        ,	HasAI = CASE WHEN js.AssociationType = 3 THEN 1 ELSE HasAI END
                        ,	HasAIGroup = CASE WHEN js.AssociationType = 4 THEN 1 ELSE HasAIGroup END
                        ,	HasIP = CASE WHEN js.AssociationType = 5 THEN 1 ELSE HasIP END;

    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasAgent) 
    SELECT 	OrigID
		,	DestID
        ,	1 AS HasAgent
	FROM JSON_TABLE(ip_Agent,
		"$[*]" COLUMNS( OrigID 			BIGINT 		PATH "$.O"                
					,	DestID			BIGINT 		PATH "$.D"
	)) AS js
    ON DUPLICATE KEY UPDATE HasAgent = 1;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasAgent) 
    SELECT 	DestID 
		,	OrigID
        ,	1 AS HasAgent
	FROM JSON_TABLE(ip_Agent,
		"$[*]" COLUMNS( OrigID 			BIGINT 		PATH "$.O"                
					,	DestID			BIGINT 		PATH "$.D"
	)) AS js
    ON DUPLICATE KEY UPDATE HasAgent = 1;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedIP)  
    SELECT 	OrigID 
		,	DestID
        ,	1 AS HasSharedIP
	FROM JSON_TABLE(ip_SharedIP,
		"$[*]" COLUMNS( OrigID 		BIGINT 		PATH "$.O"                
					,	DestID		BIGINT 		PATH "$.D"
	)) AS js
    ON DUPLICATE KEY UPDATE HasSharedIP = 1;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedIP)  
    SELECT 	DestID  
		,	OrigID
        ,	1 AS HasSharedIP
	FROM JSON_TABLE(ip_SharedIP,
		"$[*]" COLUMNS( OrigID 		BIGINT 		PATH "$.O"                
					,	DestID		BIGINT 		PATH "$.D"
	)) AS js
    ON DUPLICATE KEY UPDATE HasSharedIP = 1;
    
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedMatches)  
    SELECT 	OrigID
		,	DestID
        ,	1 AS HasSharedMatches
	FROM JSON_TABLE(ip_SharedMatches,
		"$[*]" COLUMNS( OrigID 		BIGINT 		PATH "$.O"                
					,	DestID		BIGINT 		PATH "$.D"
	)) AS js
    ON DUPLICATE KEY UPDATE HasSharedMatches = 1;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,HasSharedMatches)  
    SELECT 	DestID 
		,	OrigID
        ,	1 AS HasSharedMatches
	FROM JSON_TABLE(ip_SharedMatches,
		"$[*]" COLUMNS( OrigID 		BIGINT 		PATH "$.O"                
					,	DestID		BIGINT 		PATH "$.D"
	)) AS js
    ON DUPLICATE KEY UPDATE HasSharedMatches = 1;


    /*****************************Merge Group**************************************************/
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
        
        UPDATE Temp_Cust AS tmp
        SET tmp.Processed = 1
        WHERE  tmp.CTSCustID = lv_OrigID;
                         
		INSERT IGNORE INTO Temp_NodeCTSCustID(CTSCustID)
		WITH RECURSIVE CTE_Group AS ( 
				SELECT lv_OrigID AS OrigID
				UNION
				SELECT grp.OrigID 
				FROM Temp_Graph  AS grp
					INNER JOIN CTE_Group ON CTE_Group.OrigID = grp.DestID
		) 
		SELECT OrigID
        FROM CTE_Group AS cte
        WHERE EXISTS (SELECT 1 FROM Temp_Cust AS tmp WHERE tmp.CTSCustID = cte.OrigID);
            
		SELECT 	COUNT(1)
        INTO 	lv_Count1
        FROM Temp_NodeCTSCustID;
        
        IF lv_Count1 IS NULL OR lv_Count1 = 1 THEN
			TRUNCATE TABLE Temp_NodeCTSCustID;
        END IF;
        
        INSERT IGNORE INTO Temp_GroupID(GroupID)
        SELECT 	DISTINCT 
				gr.GroupID
        FROM Temp_GroupResult AS gr
		WHERE EXISTS (SELECT 1 FROM Temp_NodeCTSCustID AS tmp WHERE gr.CTSCustID = tmp.CTSCustID);
        
        IF EXISTS (SELECT 1 FROM Temp_GroupID) THEN
			UPDATE Temp_GroupResult AS gr
            SET gr.GroupID = lv_GroupID
            WHERE EXISTS (SELECT 1 FROM Temp_GroupID AS tmp WHERE gr.GroupID = tmp.GroupID);
        END IF;
        
        INSERT IGNORE Temp_GroupResult(CTSCustID,GroupID)
        SELECT 	CTSCustID
            ,	lv_GroupID
        FROM Temp_NodeCTSCustID;
        
        UPDATE Temp_Cust AS tmp
        SET tmp.Processed = 1
        WHERE  EXISTS (SELECT 1 FROM Temp_GroupResult AS gp WHERE  gp.CTSCustID = tmp.CTSCustID);
        
        SET lv_GroupID = lv_GroupID + 1;
        TRUNCATE TABLE Temp_NodeCTSCustID;
        TRUNCATE TABLE Temp_GroupID;
	END LOOP;

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
					,	CONCAT(IF(MAX(HasAI) =1, ", Betting Pattern","")
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
    
    IF (ip_IsGetLogTransInfo IS TRUE)
    THEN
        SET lv_ToDate	= CURRENT_DATE();
        SET lv_FromDate = DATE_ADD(lv_ToDate, INTERVAL -90 DAY);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_CustAccountID;
        CREATE TEMPORARY TABLE Temp_CustAccountID(
                    AccountID	BIGINT UNSIGNED PRIMARY KEY 
                ,	CTSCustID	BIGINT UNSIGNED 
                ,	INDEX		IX_Temp_CustAccountID(CTSCustID)
        );
        
        DROP TEMPORARY TABLE IF EXISTS Temp_CustAccLogTransInfo;
        CREATE TEMPORARY TABLE 		Temp_CustAccLogTransInfo (
                AccountID						BIGINT UNSIGNED PRIMARY KEY
            ,	CTSCustID 						BIGINT UNSIGNED
            ,	CountLogin						INT DEFAULT 0
            ,	CountBotTrans					INT DEFAULT 0
            ,	CountInvalidBrowserTrans		INT DEFAULT 0
            ,	INDEX		IX_Temp_CustAccLogTransInfo(CTSCustID)
        );

        INSERT INTO Temp_CustAccountID(CTSCustID, AccountID)
        SELECT tmp.CTSCustID, acc.AccountID
        FROM Temp_Cust AS tmp
            INNER JOIN CTS_DataCenter.CustDCSAccount AS acc ON acc.CTSCustID = tmp.CTSCustID AND acc.SubscriberID = tmp.SubscriberID
            LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = tmp.SubscriberID AND sub.SubscriberSourceID IN (lv_SubSourceID_DirectAPI, lv_SubSourceID_OddsFeed)
        WHERE sub.SubscriberSourceID IS NULL;
        
        DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransactionSummary;
        CREATE TEMPORARY TABLE Temp_LoginTransactionSummary(
                    ID			BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT
                ,   AccountID	BIGINT UNSIGNED
                ,	TotalTrans	INT UNSIGNED
                ,	Flagged		SMALLINT
                ,	INDEX		IX_Temp_LoginTransactionSummary(AccountID)
        );

        INSERT INTO Temp_LoginTransactionSummary(AccountID, TotalTrans, Flagged)
        SELECT tmp.AccountID, ls.TotalTrans, ls.Flagged
        FROM Temp_CustAccountID AS tmp
        INNER JOIN DCS_DataTrace.LoginTransactionSummary AS ls ON ls.AccountID = tmp.AccountID AND ls.TransDate BETWEEN lv_FromDate AND lv_ToDate;
        
        INSERT INTO Temp_CustAccLogTransInfo(CTSCustID, AccountID)
        SELECT tmp.CTSCustID, tmp.AccountID
        FROM Temp_CustAccountID AS tmp;
        
        UPDATE Temp_CustAccLogTransInfo AS tmp
        SET tmp.CountLogin = IFNULL((SELECT SUM(sm.TotalLogin)
                                    FROM DCS_DataCenter.SumAccountLogin AS sm
                                    WHERE sm.AccountID = tmp.AccountID AND sm.TransDate BETWEEN lv_FromDate AND lv_ToDate
                                    GROUP BY sm.AccountID),0);

        UPDATE Temp_CustAccLogTransInfo AS tmp
        SET tmp.CountLogin = IFNULL((SELECT SUM(ls.TotalTrans) 
                                    FROM Temp_LoginTransactionSummary AS ls
                                    WHERE ls.AccountID = tmp.AccountID
                                    GROUP BY ls.AccountID),tmp.CountLogin);
        
        WITH _TransCountInfo AS (
                SELECT ls.AccountID
                        ,SUM(CASE WHEN st.GroupID = 2 THEN ls.TotalTrans ELSE 0 END) AS CountInvalidBrowserTrans
                        ,SUM(CASE WHEN st.GroupID = 3 THEN ls.TotalTrans ELSE 0 END) AS CountBotTrans
                FROM Temp_LoginTransactionSummary AS ls
                    INNER JOIN DCS_DataCenter.StaticList AS st ON st.ItemID = ls.Flagged AND st.ListID = 1
                    INNER JOIN Temp_CustAccountID AS tmp ON tmp.AccountID = ls.AccountID
                GROUP BY ls.AccountID
        )
        UPDATE Temp_CustAccLogTransInfo AS tmp
            INNER JOIN _TransCountInfo tc ON tc.AccountID = tmp.AccountID
        SET tmp.CountBotTrans = tc.CountBotTrans
            , tmp.CountInvalidBrowserTrans = tc.CountInvalidBrowserTrans
        WHERE tc.CountBotTrans <> 0 OR tc.CountInvalidBrowserTrans <> 0;
        
        INSERT INTO Temp_CustLogTransInfo(CTSCustID, CountLogin, CountBotTrans, CountInvalidBrowserTrans)
        SELECT ct.CTSCustID
                , SUM(IFNULL(CountLogin,0))
                , SUM(IFNULL(CountBotTrans,0))
                , SUM(IFNULL(CountInvalidBrowserTrans,0))
        FROM Temp_CustAccLogTransInfo AS ct
        GROUP BY ct.CTSCustID;

    END IF;
    
    /*****************************Handle CustomerClass Info**************************************************/
    SELECT GROUP_CONCAT(DISTINCT CustID) 
    INTO lv_CustIDs
    FROM Temp_Cust;
    
    CALL CTS_DataCenter.CTS_DC_Common_GetCCAndDangerLevel(lv_CustIDs);
    
    SELECT 	cus.RowNumber 
		,	grp.GroupID
        ,	asTy.AssociationType
        
		,	cus.CTSCustID
        ,	cus.CustID
        ,	cus.Username
        ,	cus.CustStatus
        ,	cus.Danger1
        ,	cus.Danger2
        ,	cus.Danger3
        ,	cus.Danger4
        ,	cus.Danger5
        ,	cus.IsLicensee
        ,	cus.CreatedDate
        
        ,	re.CTSCustID AS AgentCTSCustID
        ,	re.Username AS AgentUsername
        ,	re.Evidence AS AgentEvidence
        
        
        ,	(SELECT GROUP_CONCAT(DISTINCT ' ',ev.EvidenceCode) 
			 FROM CTS_DataCenter.CustEvidence AS ce  
             LEFT JOIN CTS_DataCenter.Evidence AS ev ON ev.EvidenceID = ce.EvidenceID
             WHERE cus.CTSCustID = ce.CTSCustID) AS Evidence
        
        , 	TRIM(GROUP_CONCAT(DISTINCT ' ',cat.CategoryName)) AS CustomerCategory
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.CategoryID)) AS CategoryIDs
        ,	TRIM(GROUP_CONCAT(DISTINCT cat.ParentID)) AS ParentIDs
        ,   MAX(cat.IsPAProbation) AS IsPAProbation
        
        ,	cusclss.CustomerClass
        ,	cti.CountBotTrans AS BotTransSum
        ,	ROUND((cti.CountBotTrans/cti.CountLogin)*100,2) AS BotTransPercentage
		,	cti.CountInvalidBrowserTrans AS InvalidBrowserInfoTransSum
        ,	ROUND((cti.CountInvalidBrowserTrans/cti.CountLogin)*100,2) AS InvalidBrowserInfoTransPercentage
    FROM Temp_Cust AS cus
		LEFT JOIN Temp_GroupResult AS grp ON cus.CTSCustID = grp.CTSCustID
        LEFT JOIN Temp_CustClassificationInfo AS cusclss ON cus.CustID = cusclss.CustID
        LEFT JOIN  Temp_CustAssociationType AS asTy ON cus.CTSCustID = asTy.CTSCustID
        LEFT JOIN Temp_Recommend AS re ON cus.Recommend = re.CustID
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON cus.CustID = clss.CustID AND  clss.SportGroupID IN (CONST_GROUP_PROBLEM, CONST_GROUP_NORMAL)
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = clss.CategoryID
        LEFT JOIN Temp_CustLogTransInfo AS cti ON cti.CTSCustID = cus.CTSCustID
	GROUP BY cus.RowNumber 
		,	grp.GroupID
		,	cus.CTSCustID
        ,	cus.CustID
        ,	cus.Username
        ,	cus.CustStatus
        ,	cusclss.CustomerClass
        ,	cus.Danger1
        ,	cus.Danger2
        ,	cus.Danger3
        ,	cus.Danger4
        ,	cus.Danger5
        ,	cus.IsLicensee
        ,	cus.CreatedDate
        ,	re.CTSCustID
        ,	re.Username
        ,	re.Evidence
		,	cti.CountBotTrans
        ,	cti.CountInvalidBrowserTrans
        ,	cti.CountLogin;
END$$

DELIMITER ;
