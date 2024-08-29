/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_Robot_InitialData`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_Robot_InitialData`(
		IN		ip_Batchsize			INT
	,	IN		ip_Mode					TINYINT
	,	IN		ip_MinID				BIGINT
	,	OUT		op_NextID				BIGINT
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

	DROP TEMPORARY TABLE IF EXISTS Temp_Robot;    
	CREATE TEMPORARY TABLE Temp_Robot(	  
			ID 						BIGINT 
		,	CustID					BIGINT 
		,	CategoryID				INT
		,	RobotCounter			SMALLINT
		,	Remark 					VARCHAR(500)
		,	CreatedDate				DATETIME
		,	IsFromCTS				TINYINT(1)
		,	IsFromTW				TINYINT(1)
		,	PRIMARY KEY (ID)
	);

	IF ip_Mode = 1 THEN

		INSERT INTO Temp_Robot (ID, CustID, CategoryID, RobotCounter, Remark, CreatedDate, IsFromCTS, IsFromTW)
		SELECT h.ID, h.CustID, h.CategoryID, h.RobotCounter, h.Remark, h.CreatedDate, h.IsFromCTS, h.IsFromTW
		FROM CTS_DataCenter.CTSCustomerClassification_History AS h
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CTSCustID = h.CTSCustID 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = h.CTSCustID AND cust.CustSubID = 0
		WHERE h.ID >= ip_MinID
			AND h.ParentID = CONST_PARENTID_PA
			AND h.CategoryID = cc.CategoryID
			AND ((h.IsFromCTS = 1 AND cc.IsFromCTS = 1)
				OR (h.IsFromTW = 1 AND cc.IsFromTW = 1))
		ORDER BY h.ID
		LIMIT ip_Batchsize;
		
		SELECT MAX(ID)
		INTO lv_NextID
		FROM Temp_Robot;
		
		SET op_NextID = IFNULL(lv_NextID,0);
		
		UPDATE CTS_DataCenter.SystemParameter 
		SET ParameterValue = op_NextID
		WHERE ParameterID = 994; 
		
		IF op_NextID = 0 THEN
			LEAVE sp;
		END IF;
		
		IF EXISTS (SELECT 1 FROM Temp_Robot WHERE IsFromCTS = 1) THEN
			
			INSERT INTO CTSRobotUser (CustID, CategoryID, Remark, CreatedDate, InsertedTime)
			SELECT temp.CustID, temp.CategoryID, temp.Remark, temp.CreatedDate, NOW()
			FROM Temp_Robot AS temp
			WHERE temp.IsFromCTS = 1
			ON DUPLICATE KEY UPDATE 	CategoryID = temp.CategoryID
									,	Remark = temp.Remark
									,	CreatedDate = temp.CreatedDate;
			
			
		END IF;
		
		IF EXISTS (SELECT 1 FROM Temp_Robot WHERE IsFromTW = 1) THEN
			
			INSERT INTO TWRobotUser (CustID, CategoryID, RobotCounter, CreatedDate, InsertedTime)
			SELECT temp.CustID, temp.CategoryID, temp.RobotCounter, temp.CreatedDate, NOW()
			FROM Temp_Robot AS temp
			WHERE temp.IsFromTW = 1
			ON DUPLICATE KEY UPDATE 	CategoryID = temp.CategoryID
									,	RobotCounter = temp.RobotCounter
									,	CreatedDate = temp.CreatedDate;
		END IF;
	END IF;
	
END$$
DELIMITER ;