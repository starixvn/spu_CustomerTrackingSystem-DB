/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_DataConsistency_CustomerCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_DataConsistency_CustomerCategory`(
	IN 	ip_Batchsize		INT
,	IN 	ip_MinCustID		BIGINT
,	OUT	op_NextCustID		BIGINT
)
    SQL SECURITY INVOKER
spc:BEGIN 
	/*
		Created:	20241018@Victoria.Le
		Task :		Identify customers who are classified incorrectly on the CTS side.
		DB:			CTS_DataCenter  

		Revisions:
			- 20241018@Victoria.Le: 	Initial Writing [RedmineID: #212321]
                
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_DataConsistency_CustomerCategory(1000,0,@op_NextCustID);
	*/ 
	
	/*Get value*/
	DECLARE CONST_PARENTID_WRAPPER				INT;
	DECLARE CONST_PARENTID_PA					INT;
	DECLARE	CONST_CATEID_VVIP					INT;

	DECLARE lv_MaxCustID						BIGINT;
	
	SET CONST_PARENTID_WRAPPER					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 						= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_CATEID_VVIP	 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCateInfo;
    CREATE TEMPORARY TABLE Temp_CustCateInfo (
        	CustID						BIGINT UNSIGNED 
		,	ParentID					INT
		,	CategoryID					INT        
		,	IsPAProbation 				TINYINT(1) DEFAULT 0
		,	IsKeepOldCateID				TINYINT(1) DEFAULT 0
		,	IsVVIP						TINYINT(1) DEFAULT 0
		,	IsPA						TINYINT(1) DEFAULT 0
		,	IsWrapper					TINYINT(1) DEFAULT 0
		,	PRIMARY KEY (CustID,ParentID,CategoryID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIssue;
    CREATE TEMPORARY TABLE Temp_CustIssue (
        	CustID						BIGINT UNSIGNED PRIMARY KEY
	);
    
	/*Start*/
	WITH CTE AS
	(
		SELECT DISTINCT cc.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS cc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID  = 0
		WHERE cc.CustID	> ip_MinCustID
		ORDER BY cc.CustID
		LIMIT ip_Batchsize
	)
	SELECT MAX(CustID)
	INTO lv_MaxCustID
	FROM CTE;
	
	IF lv_MaxCustID IS NULL THEN
		SET op_NextCustID = 0;
		LEAVE spc;
	ELSE
		SET op_NextCustID = lv_MaxCustID;
	END IF;
	
	INSERT IGNORE INTO Temp_CustCateInfo (CustID,ParentID,CategoryID,IsPAProbation,IsKeepOldCateID,IsVVIP,IsPA,IsWrapper)
	SELECT 	cc.CustID,cc.ParentID,cc.CategoryID,cate.IsPAProbation,cs.IsKeepOldCateID
		,	CASE WHEN cc.CategoryID = CONST_CATEID_VVIP THEN 1 ELSE 0 END AS IsVVIP
		,	CASE WHEN cc.ParentID = CONST_PARENTID_PA THEN 1 ELSE 0 END AS IsPA
		,	CASE WHEN cc.ParentID = CONST_PARENTID_WRAPPER THEN 1 ELSE 0 END AS IsWrapper
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID  = 0
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = cc.CategoryID 
		INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cate.CategoryID 
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = cc.CustID
	WHERE cc.CustID > ip_MinCustID
		AND cc.CustID <= lv_MaxCustID;
		
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCateInfo_Dup;
	CREATE TEMPORARY TABLE Temp_CustCateInfo_Dup AS 
		SELECT CustID,ParentID,CategoryID,IsPAProbation,IsKeepOldCateID,IsVVIP,IsPA,IsWrapper
		FROM Temp_CustCateInfo;
    /*    
	UPDATE Temp_CustCateInfo AS temp1
	SET temp1.IsWrapper = 1
    WHERE EXISTS (SELECT 1 FROM Temp_CustCateInfo_Dup AS temp2 WHERE temp2.CustID = temp1.CustID AND temp2.ParentID = CONST_PARENTID_WRAPPER)
    ;	*/
	-- 1. VVIP: only allow exists IsKeepOldCateID = 1 with CategoryID <> VVIP
	INSERT IGNORE INTO Temp_CustIssue(CustID)
	WITH CTE AS
	(
		SELECT DISTINCT CustID
		FROM Temp_CustCateInfo
		WHERE IsVVIP = 1
	)
	SELECT DISTINCT temp.CustID
	FROM Temp_CustCateInfo_Dup AS temp
		INNER JOIN CTE AS c ON c.CustID = temp.CustID
	WHERE temp.IsVVIP = 0
		AND temp.IsKeepOldCateID = 0;

	-- 2.1. PA: only allow exists IsKeepOldCateID = 1 with CategoryID <> VVIP & CategoryID <> PA
	-- 2.2. PA: Enable only one value on one flag for one customer
	INSERT IGNORE INTO Temp_CustIssue(CustID)
	WITH CTE AS
	(
		SELECT 	CustID,IsPAProbation
			,	ROW_NUMBER() OVER (PARTITION BY CustID,IsPAProbation ORDER BY IsPAProbation) AS RN
		FROM Temp_CustCateInfo
		WHERE IsVVIP = 0 AND IsWrapper = 0
		GROUP BY CustID,IsPAProbation
	)
	SELECT DISTINCT temp.CustID
	FROM Temp_CustCateInfo_Dup AS temp
		INNER JOIN CTE AS c ON c.CustID = temp.CustID
	WHERE c.RN > 1;
        
	INSERT IGNORE INTO Temp_CustIssue(CustID)
	WITH CTE AS
	(
		SELECT 	CustID,IsPAProbation
			,	ROW_NUMBER() OVER (PARTITION BY CustID,IsPAProbation ORDER BY IsPAProbation) AS RN
		FROM Temp_CustCateInfo
		WHERE IsVVIP = 0 AND IsWrapper = 1
		GROUP BY CustID,IsPAProbation
	)
	SELECT DISTINCT temp.CustID
	FROM Temp_CustCateInfo_Dup AS temp
		INNER JOIN CTE AS c ON c.CustID = temp.CustID
	WHERE c.RN > 1;

	-- 3. Normal: only allow 1 record for each customer (not exists CategoryID = VVIP or CategoryID = PA)
	INSERT IGNORE INTO Temp_CustIssue(CustID)
	WITH CTE AS
	(
		SELECT 	CustID,IsPAProbation
			,	ROW_NUMBER() OVER (PARTITION BY CustID,IsPAProbation ORDER BY IsPAProbation) AS RN
		FROM Temp_CustCateInfo
		WHERE IsVVIP = 0 AND IsPA = 0 
		GROUP BY CustID,IsPAProbation
	)
	SELECT DISTINCT temp.CustID
	FROM Temp_CustCateInfo_Dup AS temp
		INNER JOIN CTE AS c ON c.CustID = temp.CustID
	WHERE c.RN > 1;
END$$

DELIMITER ;