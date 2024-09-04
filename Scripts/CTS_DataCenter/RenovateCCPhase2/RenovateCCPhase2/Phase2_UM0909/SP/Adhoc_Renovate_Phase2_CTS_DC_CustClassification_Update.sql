/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update`(
		IN		ip_Batchsize			INT
	,	IN		ip_SportGroupID			INT
	,	IN		ip_CategoryID			INT
	,	IN		ip_MinCustID			BIGINT
	,	IN		ip_TotalCust			BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240829@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(10000,200,201,402076,140714);
			
		Revisions: 
			- 20240829@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DECLARE CONST_CATEGORYGROUP_PROBATION	INT DEFAULT 206;
	DECLARE lv_FromID						BIGINT DEFAULT 0;
	DECLARE lv_ToID							BIGINT DEFAULT 0;
	DECLARE lv_FromID_Next					BIGINT DEFAULT 0;
	DECLARE lv_ToID_Next					BIGINT DEFAULT 0;
	DECLARE lv_TotalCustUpdated				BIGINT DEFAULT 0;
	DECLARE lv_UpdatedCount					BIGINT DEFAULT 0;
	DECLARE lv_TotalCust					BIGINT;
	DECLARE lv_IsProbation					TINYINT(1) DEFAULT 0;
	DECLARE lv_IsRobot						TINYINT(1) DEFAULT 0;
	DECLARE lv_RelevantCateID				INT;
	DECLARE lv_RobotTW_MinID				BIGINT;
	DECLARE lv_RobotTW_MaxID				BIGINT;
	DECLARE lv_RobotCTS_MinID				BIGINT;
	DECLARE lv_RobotCTS_MaxID				BIGINT;
	DECLARE lv_RobotTW_MinID_ParamID		BIGINT DEFAULT 890;
	DECLARE lv_RobotTW_MaxID_ParamID		BIGINT DEFAULT 889;
	DECLARE lv_RobotCTS_MinID_ParamID		BIGINT DEFAULT 888;
	DECLARE lv_RobotCTS_MaxID_ParamID		BIGINT DEFAULT 887;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			ID					BIGINT UNSIGNED AUTO_INCREMENT
		,	CustID				BIGINT UNSIGNED
		,	CategoryID			INT
		,	CreatedDate			DATETIME
		,	LastScannedDate		DATETIME
		,	IsFromTW			TINYINT(1)			
		,	IsFromCTS			TINYINT(1)		
		,	IsFromTVS			TINYINT(1)		
		,	TVSRequestID		BIGINT	
		,	IssueTypeID			TINYINT	
		,	IsParlay			TINYINT(1)		
		,	SportType			INT	
		,	PRIMARY KEY (ID)
	);
	
	SELECT 1
	INTO lv_IsProbation
	FROM CTS_DataCenter.CustomerCategory
	WHERE CategoryID = ip_CategoryID
		AND Ext_CategoryGroupID = CONST_CATEGORYGROUP_PROBATION;
		
	IF ip_SportGroupID = 0 THEN
		IF ip_CategoryID IN (163,164) THEN
			SET lv_IsRobot = 1;
		END IF;
		
		SELECT RelevantCategoryID
		INTO lv_RelevantCateID
		FROM CTS_DataCenter.CustomerCategory_Arc
		WHERE CategoryID = ip_CategoryID;
		
	END IF;
	
	INSERT INTO Temp_Customer (CustID,CategoryID,CreatedDate,LastScannedDate
		,	IsFromTW,IsFromCTS,IsFromTVS,TVSRequestID,IssueTypeID,IsParlay,SportType)
	SELECT cc.CustID,cc.CategoryID,cc.CreatedDate,cc.LastScannedDate
		,	cc.IsFromTW,cc.IsFromCTS,cc.IsFromTVS,cc.TVSRequestID,cc.IssueTypeID,cc.IsParlay,cc.SportType
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
	WHERE cc.SportGroupID = ip_SportGroupID
		AND cc.CategoryID = ip_CategoryID
		AND cc.CustID >= ip_MinCustID
	ORDER BY cc.CustID;
	
	WITH CTE AS
	(	SELECT temp.ID
		FROM Temp_Customer AS temp
		ORDER BY temp.ID
		LIMIT ip_Batchsize
	)
	SELECT MIN(c.ID),MAX(c.ID)
	INTO lv_FromID, lv_ToID
	FROM CTE AS c;
	
	SET lv_TotalCust = ip_TotalCust;
	
	WHILE (lv_TotalCust > 0 AND lv_FromID > 0 AND lv_ToID > 0)
	DO
		SET lv_UpdatedCount = 0;
		
		-- OPTION 1: ONLY UPDATE CreatedDate/LastScannedDate for PROBATION
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
			INNER JOIN Temp_Customer AS temp ON cc.CustID = temp.CustID 
												AND cc.SportGroupID = ip_SportGroupID
												AND cc.CategoryID = ip_CategoryID
		SET 	cc.CreatedDate 			= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE cc.CreatedDate END
			,	cc.LastScannedDate 		= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE cc.LastScannedDate END
			,	cc.CreatedDate_new 		= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE NULL END
			,	cc.LastScannedDate_new 	= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE NULL END
		WHERE temp.ID BETWEEN lv_FromID AND lv_ToID;
		
		-- OPTION 2: UPDATE COLUMNS suffix _new >> existing
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
			INNER JOIN Temp_Customer AS temp ON cc.CustID = temp.CustID 
												AND cc.SportGroupID = ip_SportGroupID
												AND cc.CategoryID = ip_CategoryID
		SET 	cc.ParentID 			= cc.ParentID_new
			,	cc.CategoryID 			= cc.CategoryID_new
			,	cc.CreatedDate 			= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE cc.CreatedDate END
			,	cc.LastScannedDate 		= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE cc.LastScannedDate END
			,	cc.CreatedDate_new 		= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE NULL END
			,	cc.LastScannedDate_new 	= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE NULL END
		WHERE temp.ID BETWEEN lv_FromID AND lv_ToID;
		
		SET lv_UpdatedCount = FOUND_ROWS();
		SET lv_TotalCustUpdated = lv_TotalCustUpdated + lv_UpdatedCount;
		SET lv_TotalCust = lv_TotalCust - lv_UpdatedCount;
		
		-- --------------------------------- 
		/* INSERT INTO TABLE SOURCE */
		-- ---------------------------------
			/* ROBOT */
			IF lv_IsRobot = 1 THEN
				-- ROBOT TW
				IF EXISTS (SELECT 1 FROM Temp_Customer WHERE IsFromTW = 1) THEN
				
					SELECT ParameterValue
					INTO lv_RobotTW_MinID
					FROM SystemParameter
					WHERE ParameterID = lv_RobotTW_MinID_ParamID;
					
					SELECT ParameterValue
					INTO lv_RobotTW_MaxID
					FROM SystemParameter
					WHERE ParameterID = lv_RobotTW_MaxID_ParamID;
					
					INSERT IGNORE INTO TWRobotUser (CustID, CategoryID, RobotCounter, CreatedDate, InsertedTime)
					SELECT 	cust.CustID
						, 	cate.CategoryID
						, 	h.RobotCounter
						, 	h.InsertDate AS CreatedDate
						, 	NOW() AS InsertedTime
					FROM Temp_Customer AS cust
						INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON h.CustID = cust.CustID		
						INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.OldCategoryID = h.CategoryID
					WHERE cust.IsFromTW = 1 
						AND h.ID >= lv_RobotTW_MinID AND h.ID <= lv_RobotTW_MaxID
						AND h.CategoryID IN (ip_CategoryID,lv_RelevantCateID)
						AND h.IsFromTW = 1
					ORDER BY h.ID DESC;
					
				END IF;
				
				-- ROBOT CTS
				IF EXISTS (SELECT 1 FROM Temp_Customer WHERE IsFromCTS = 1) THEN
					
					SELECT ParameterValue
					INTO lv_RobotCTS_MinID
					FROM SystemParameter
					WHERE ParameterID = lv_RobotCTS_MinID_ParamID;
					
					SELECT ParameterValue
					INTO lv_RobotCTS_MaxID
					FROM SystemParameter
					WHERE ParameterID = lv_RobotCTS_MaxID_ParamID;
					
					INSERT IGNORE INTO CTSRobotUser (CustID, CategoryID, Remark, CreatedDate, InsertedTime)
					SELECT 	cust.CustID
						, 	cate.CategoryID
						, 	h.Remark
						, 	h.InsertDate AS CreatedDate
						, 	NOW() AS InsertedTime
					FROM Temp_Customer AS cust
						INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON h.CustID = cust.CustID		
						INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.OldCategoryID = h.CategoryID
					WHERE cust.IsFromCTS = 1 
						AND h.ID >= lv_RobotCTS_MinID AND h.ID <= lv_RobotCTS_MaxID
						AND h.CategoryID IN (ip_CategoryID,lv_RelevantCateID)
						AND h.IsFromCTS = 1
					ORDER BY h.ID DESC;
					
				END IF;
			
			ELSE IF lv_IsRobot = 0 AND ip_SportGroupID = 0 THEN
					IF EXISTS (SELECT 1 FROM Temp_Customer WHERE IsFromTVS = 1) THEN
						
						INSERT INTO TVSVoidRequest (CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID, ReasonID, CreatedBy, CreatedDate, RequestTypeID, IsDisable)
						SELECT CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID, ReasonID, CreatedBy, CreatedDate, 1, IsDisable
						FROM Adhoc_TVSVoidRequest_CC AS tvs
						WHERE IsCheck = 1
						ORDER BY ID ASC;
						
					END IF;
			
				END IF;
			
            END IF;
		
		
			WITH CTE AS
			(	SELECT temp.ID
				FROM Temp_Customer AS temp
				WHERE temp.ID > lv_ToID
				ORDER BY temp.ID
				LIMIT ip_Batchsize
			)
			SELECT MIN(c.ID),MAX(c.ID)
			INTO lv_FromID_Next, lv_ToID_Next
			FROM CTE AS c;
			
			IF lv_FromID_Next > 0 AND lv_ToID_Next > 0 
				AND lv_FromID_Next <> lv_FromID AND lv_ToID_Next <> lv_ToID 
				AND lv_FromID_Next > lv_FromID AND lv_ToID_Next > lv_ToID THEN
			
				SET lv_FromID = lv_FromID_Next;
				SET lv_ToID = lv_ToID_Next;
			
			ELSE
			
				SET lv_FromID = 0;
				SET lv_ToID = 0;
				
			END IF;
	END WHILE;
	
	SELECT 	ip_Batchsize AS Batchsize
		,	ip_SportGroupID AS SportGroupID
		,	ip_CategoryID AS CategoryID
		,	ip_MinCustID AS MinCustID
		,	ip_TotalCust AS TotalCust
		,	lv_TotalCustUpdated AS TotalCustUpdated;

END$$
DELIMITER ;