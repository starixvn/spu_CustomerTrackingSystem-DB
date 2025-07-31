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
	
	SET @CONST_AGENCY_PARENTID_NORMAL := 140000;
    SET	@CONST_PARENTID_VVIP := 1000;

	DROP TEMPORARY TABLE IF EXISTS Temp_AgentList;
    CREATE TEMPORARY TABLE Temp_AgentList(
			AgentID	BIGINT UNSIGNED PRIMARY KEY
    ); 

	DROP TEMPORARY TABLE IF EXISTS Temp_AgentConsiderableDanger;
    CREATE TEMPORARY TABLE Temp_AgentConsiderableDanger(
			CustID	BIGINT UNSIGNED PRIMARY KEY
		,	TotalCust	INT DEFAULT 0
		,	TotalPACust	INT DEFAULT 0
		,	PAMemberRatio	DECIMAL(5,2) DEFAULT 0
		,   IsPassRuleRatio  BIT DEFAULT 0 
    ); 
	
	INSERT IGNORE INTO Temp_AgentList (AgentID)
	SELECT cus.CustID
	FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationAgency AS cls 
				ON cls.CustID = cus.CustID  
				AND cls.ParentID IN (@CONST_AGENCY_PARENTID_NORMAL)
	WHERE cus.RoleID = 2
		AND cus.IsLicensee = 0
		AND cus.CustSubID = 0;
     
	INSERT IGNORE INTO Temp_AgentConsiderableDanger (CustID, TotalCust, TotalPACust) 
	SELECT AgentID, COUNT( Distinct cus.CTSCustID) AS TotalCust, 
			SUM(CASE WHEN cate.IsPA > 0 AND cate.IsVVIP = 0 THEN 1 ELSE 0 END) AS TotalPA 
	FROM Temp_AgentList AS tac
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.Recommend = tac.AgentID
	LEFT JOIN LATERAL	(SELECT cls.CustID
								, SUM(CASE WHEN ccs.FlowConsiderableDangerScan = 1 THEN 1 ELSE 0 END) AS IsPA 
                                , SUM(CASE WHEN ccs.ParentID = @CONST_PARENTID_VVIP THEN 1 ELSE 0 END) AS IsVVIP
							FROM CTS_DataCenter.CTSCustomerClassification AS cls
								INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON cls.CategoryID = ccs.CategoryID
							WHERE cls.CustID = cus.CustID
                            GROUP BY cls.CustID
						) AS cate ON TRUE
	WHERE cus.RoleID = 1
    GROUP BY tac.AgentID;

	UPDATE Temp_AgentConsiderableDanger AS tac
	SET tac.IsPassRuleRatio = CASE WHEN tac.TotalCust > 0 THEN (CASE WHEN CAST(tac.TotalPACust*100/tac.TotalCust AS DECIMAL(5,2)) >= 50 THEN 1 ELSE 0 END) ELSE 0 END
		,tac.PAMemberRatio = CASE WHEN tac.TotalCust > 0 THEN CAST(tac.TotalPACust*100/tac.TotalCust AS DECIMAL(5,2)) ELSE 0 END
        ;
    
	SELECT CustID	
	,	TotalCust	
	,	TotalPACust	
	,   IsPassRuleRatio
	,	PAMemberRatio
	FROM Temp_AgentConsiderableDanger AS tac
    WHERE tac.IsPassRuleRatio = 1;

	INSERT IGNORE INTO CTS_DataCenter.CustomerConsiderableDangerQueue(CustID, ScanType, InsertedTime)
    SELECT DISTINCT js.CustID
		,	2 AS ScanType	
		,	CURRENT_TIMESTAMP(3) AS InsertedTime
	FROM Temp_AgentConsiderableDanger AS js 
    WHERE js.IsPassRuleRatio = 1 AND
	NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CustomerConsiderableDangerQueue AS clss WHERE clss.CustID = js.CustID AND clss.ScanType = 1);
