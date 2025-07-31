/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250725@Winfred.Pham
Task:	 	
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250725@Winfred.Pham: Inital Data Agent [Redmine ID: #219679]
Reviewer:
*/

USE CTS_DataCenter;

#================================================================================
	
	SET @CONST_AGENCY_PARENTID_NORMAL := CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_PARENTID_NORMAL');
	SET @lv_MinQueueID	:= 0;

    SELECT sys.ParameterValue
    INTO @lv_MinQueueID
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE ParameterID = 192;  

	DROP TEMPORARY TABLE IF EXISTS Temp_AgentList;
    CREATE TEMPORARY TABLE Temp_AgentList(
			AgentID	BIGINT UNSIGNED
    ); 

	DROP TEMPORARY TABLE IF EXISTS Temp_AgentConsiderableDanger;
    CREATE TEMPORARY TABLE Temp_AgentConsiderableDanger(
			CustID	BIGINT UNSIGNED 
		,	TotalCust	INT
		,	TotalPACust	INT
		,	PAMemberRatio	DECIMAL(5,2)
		,   IsPassRuleRatio  BIT DEFAULT 0 
        ,	INDEX	IX_Temp_AgentConsiderableDanger_CustID(CustID)  
    ); 
	
	INSERT IGNORE INTO Temp_AgentList (AgentID)
	SELECT cus.CustID
	FROM CTS_DataCenter.CTSCustomer AS cus
		,	LATERAL (
			SELECT cus.CustID, cls.ParentID
			FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
				INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON cate.CategoryID = cls.CategoryID
			WHERE cls.CustID = cus.CustID AND cate.IsActive = 1
			ORDER BY cate.CustomerClassPriority ASC, cls.LastModifiedDate DESC
			LIMIT 1
		) AS clss
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationAgency AS cls 
				ON cls.CustID = clss.CustID AND cls.ParentID = clss.ParentID 
				AND cls.ParentID IN (@CONST_AGENCY_PARENTID_NORMAL)
	WHERE cus.RoleID = 2
		AND cus.IsLicensee = 0
		AND cus.CustSubID = 0;
     
	INSERT IGNORE INTO Temp_AgentConsiderableDanger (CustID, TotalCust, TotalPACust) 
	SELECT AgentID, COUNT(cus.CTSCustID) AS TotalCust, 
			SUM(CASE WHEN EXISTS (SELECT 1  FROM CTS_DataCenter.CustomerCategorySettings AS cls WHERE cls.CategoryID = ccc.CategoryID AND cls.FlowConsiderableDangerScan = 1) 
					 THEN 1 ELSE 0 END ) AS TotalPA 
	FROM Temp_AgentList AS tac
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.Recommend = tac.AgentID
	LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS ccc ON cus.CustID = ccc.CustID
	WHERE cus.RoleID = 1
    GROUP BY tac.AgentID;

	UPDATE Temp_AgentConsiderableDanger AS tac
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tac.CustID = cus.CustID AND cus.IsLicensee = 0 AND cus.RoleID = 2 AND cus.CustSubID = 0
		,LATERAL	(
							SELECT cls.CategoryID
							FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
								INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
							WHERE cls.CustID = tac.CustID
							ORDER BY  cate.CustomerClassPriority ASC 
									, cls.LastModifiedDate DESC
							LIMIT 1
						) AS cate
	SET tac.IsPassRuleRatio = (CASE WHEN CAST(tac.TotalPACust*100/tac.TotalCust AS DECIMAL(5,2)) >= 50 THEN 1 ELSE 0 END)
        ,tac.PAMemberRatio = CAST(tac.TotalPACust*100/tac.TotalCust AS DECIMAL(5,2));
    
	SELECT CustID	
	,	TotalCust	
	,	TotalPACust	
	,   IsPassRuleRatio
	,	PAMemberRatio
	,   CTSCustID
	FROM Temp_AgentConsiderableDanger AS tac
    WHERE tac.IsPassRuleRatio = 1;

	INSERT IGNORE INTO CTS_DataCenter.CustomerConsiderableDangerQueue(CustID, ScanType, InsertedTime)
    SELECT DISTINCT js.CustID
		,	2 AS ScanType	
		,	CURRENT_TIMESTAMP(3) AS InsertedTime
	FROM Temp_AgentConsiderableDanger AS js 
    WHERE js.IsPassRuleRatio = 1 AND
	NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CustomerConsiderableDangerQueue AS clss WHERE clss.ID > @lv_MinQueueID 
	 								AND clss.CustID = js.CustID AND clss.ScanType = 1);
