/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_Robot_InitialData`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_PA_InitialData`(
		IN		ip_Batchsize			INT
	,	IN		ip_CustID				BIGINT
	,	IN		ip_CategoryID			BIGINT
	,	OUT		op_CustID				BIGINT
)
    SQL SECURITY INVOKER
sp:BEGIN 
/*
		Created:	20240809@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_Robot_InitialData(9);
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/

	DECLARE lv_NextID						BIGINT DEFAULT 0;

	DECLARE CONST_PARENTID_PA				INT;
	
	SET op_NextID							= 0;
	SET CONST_PARENTID_PA 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');

	DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
			ID 						BIGINT 
		,	TVSRequestID			BIGINT 
		,	CustID					BIGINT 
		,	CategoryID				INT
		,	TVSReasonID				INT
		,	IssueTypeID				TINYINT
		,	CreatedBy				INT
		,	IsParlay				TINYINT(1)
		,	SportType				INT
		,	CreatedDate				DATETIME
		,	IsInserted				TINYINT(1)
		,	PRIMARY KEY (ID)
	);

	INSERT INTO Temp_PA (ID, TVSRequestID, CustID, CategoryID, IssueTypeID, IsParlay, SportType)
	SELECT h.ID, h.CustID, h.CategoryID, h.IssueTypeID, h.IsParlay, h.SportType
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = cc.CTSCustID AND cust.CustSubID = 0
	WHERE cc.ID >= ip_MinID
		AND cc.ParentID = CONST_PARENTID_PA
		AND cc.IsFromTVS = 1
	ORDER BY h.ID
	LIMIT ip_Batchsize;
	
	
	
	SELECT MAX(ID)
	INTO lv_NextID
	FROM Temp_PA;
	
	SET op_NextID = IFNULL(lv_NextID,0);
	
	UPDATE CTS_DataCenter.SystemParameter 
	SET ParameterValue = op_NextID
	WHERE ParameterID = 994; 
	
	IF op_NextID = 0 THEN
		LEAVE sp;
	END IF;
	
	IF EXISTS (SELECT 1 FROM Temp_PA WHERE IsFromCTS = 1) THEN
		
		INSERT INTO CTSRobotUser (CustID, CategoryID, IssueTypeID, CreatedDate, InsertedTime)
		SELECT temp.CustID, temp.CategoryID, temp.IssueTypeID, temp.CreatedDate, NOW()
		FROM Temp_PA AS temp
		WHERE temp.IsFromCTS = 1
		ON DUPLICATE KEY UPDATE 	CategoryID = temp.CategoryID
								,	IssueTypeID = temp.IssueTypeID
								,	CreatedDate = temp.CreatedDate;
		
		
	END IF;
	
	IF EXISTS (SELECT 1 FROM Temp_PA WHERE IsFromTW = 1) THEN
		
		INSERT INTO TWRobotUser (CustID, CategoryID, TVSReasonID, CreatedDate, InsertedTime)
		SELECT temp.CustID, temp.CategoryID, temp.TVSReasonID, temp.CreatedDate, NOW()
		FROM Temp_PA AS temp
		WHERE temp.IsFromTW = 1
		ON DUPLICATE KEY UPDATE 	CategoryID = temp.CategoryID
								,	TVSReasonID = temp.TVSReasonID
								,	CreatedDate = temp.CreatedDate;
	END IF;
	
END$$
DELIMITER ;