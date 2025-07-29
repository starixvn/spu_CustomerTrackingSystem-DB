/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassificationAgency_DetectCD`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassificationAgency_DetectCD`(		
		IN 	ip_Cust	 LONGTEXT
        ,IN ip_IsRescan BIT 
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250725@Winfred.Pham
		Task:	 Get Agent cust List Considerable Danger Queue    
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250725@Winfred.Pham: 	Created [Redmine ID: #219679]
                
		Param's Explanation :
        
		Example:
			CALL CTS_DC_CustClassificationAgency_DetectCD(@ip_BatchSize:=100,OUT op_LastID :=@op_LastID);
	*/
    DECLARE	CONST_AGENCY_CATEID_CD_LOW INT DEFAULT 121800;
    DECLARE	CONST_AGENCY_CATEID_CD_HIGHT INT DEFAULT 126800;

    IF ip_IsRescan IS NULL THEN
        SET ip_IsRescan = 0;
    END IF;

	DROP TEMPORARY TABLE IF EXISTS Temp_AgentList;
    CREATE TEMPORARY TABLE Temp_AgentList(
			AgentID	BIGINT UNSIGNED
    ); 

	DROP TEMPORARY TABLE IF EXISTS Temp_AgentConsiderable;
    CREATE TEMPORARY TABLE Temp_AgentConsiderable(
			CustID	BIGINT UNSIGNED 
        ,   CTSCustID BIGINT UNSIGNED DEFAULT 0
		,	TotalCust	INT
		,	TotalPACust	INT
		,	PAMemberRatio	DECIMAL(5,2)
		,   IsPassRuleConsiderable  BIT DEFAULT 0 
		,   IsPassRuleRatio  BIT DEFAULT 0 
        ,	INDEX	IX_Temp_AgentConsiderable_CustID(CustID)  
    ); 

    CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_Cust,',','BIGINT');
            
	INSERT IGNORE INTO Temp_AgentList (AgentID) SELECT * FROM TempItemTable;   

	INSERT IGNORE INTO Temp_AgentConsiderable (CustID, CTSCustID, TotalCust, TotalPACust) 
	SELECT AgentID, cus.CTSCustID,  COUNT(cus.CTSCustID) AS TotalCust, 
			SUM(CASE WHEN EXISTS (SELECT 1  FROM CTS_DataCenter.CustomerCategorySettings AS cls WHERE cls.CategoryID = ccc.CategoryID AND cls.FlowConsiderableDangerScan = 1) 
					 THEN 1 ELSE 0 END ) AS TotalPA 
	FROM Temp_AgentList AS tac
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.Recommend = tac.AgentID
	LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS ccc ON cus.CustID = ccc.CustID
	WHERE cus.RoleID = 1
    GROUP BY tac.AgentID, cus.CTSCustID;

	UPDATE Temp_AgentConsiderable AS tac
		,LATERAL	(
							SELECT cls.CategoryID
							FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
								INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
							WHERE cls.CustID = tac.CustID
							ORDER BY  cate.CustomerClassPriority ASC 
									, cls.LastModifiedDate DESC
							LIMIT 1
						) AS cate
	SET tac.IsPassRuleConsiderable = (CASE WHEN cate.CategoryID IN (CONST_AGENCY_CATEID_CD_LOW,CONST_AGENCY_CATEID_CD_HIGHT) THEN 1 ELSE 0 END)
        ,tac.IsPassRuleRatio = (CASE WHEN CAST(tac.TotalPACust*100/tac.TotalCust AS DECIMAL(5,2)) >= 50 THEN 1 ELSE 0 END)
        ,tac.PAMemberRatio = CAST(tac.TotalPACust*100/tac.TotalCust AS DECIMAL(5,2))
    WHERE CustID IS NOT NULL
        AND CustID > 0;
    
    INSERT INTO CTS_DataCenter.Customer_ConsiderableDanger(CustID, CTSCustID, TotalMember, TotalPAMember, PAMemberRatio, InsertedTime)
    SELECT CustID, CTSCustID, TotalCust, TotalPACust, PAMemberRatio, CURRENT_TIMESTAMP(3) AS InsertedTime
    FROM Temp_AgentConsiderable AS tac
    WHERE IsPassRuleRatio = 1;

    INSERT INTO CTS_DataCenter.Customer_ConsiderableDanger_Log(CustID, CTSCustID, TotalMember, TotalPAMember, PAMemberRatio, InsertedTime)
    SELECT CustID, CTSCustID, TotalCust, TotalPACust, PAMemberRatio, CURRENT_TIMESTAMP(3) AS InsertedTime
    FROM Temp_AgentConsiderable AS tac;

    IF ip_IsRescan = 0 THEN
        SELECT CustID	
		,	TotalCust	
		,	TotalPACust	
		,   IsPassRuleConsiderable  
		,   IsPassRuleRatio
	    FROM Temp_AgentConsiderable AS tac;
    END IF;

END$$
DELIMITER ;