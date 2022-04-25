/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_ClearEvidence`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_ClearEvidence`(
		IN ip_CTSCustIDList 		VARCHAR(8000)
    
    ,	OUT op_ErrorMessage 		VARCHAR(200) 
    ,	OUT op_Result 				VARCHAR(8000)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Clear customer evidences [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
			- 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
			- 20210622@Aries.Nguyen: Update coding convention and improve locking  [Redmine ID: #157203]
			- 20210823@Aries.Nguyen: Enhannce  Affected Evidence flow [Redmine ID: #160470]
			- 20210920@Aries.Nguyen: Split history log  [Redmine ID: #161890]
			- 20220414@Aries.Nguyen: Add new category/class for PA Probation [Redmine ID: #170468]

		Param's Explanation (filtered by):   
			- ActionID: 1 insert, 2 override, 3 clear
            
		Example:			
			- CALL CTS_DataCenter.CTS_DC_CustEvidence_ClearEvidence('8', @op_ErrorMessage);
	*/
        
    DECLARE	lv_CurrentDateTime 		DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy 			BIGINT DEFAULT  10278938;
    DECLARE	lv_IsSyncEvi2Category 	VARCHAR(1) DEFAULT '';  
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerID;
    CREATE TEMPORARY TABLE 		Temp_CustomerID (
			CustID 				BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	PRIMARY KEY     	PK_Temp_CustomerID_CTSCustID_CustID(CTSCustID,CustID)
	);  
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID;
    CREATE TEMPORARY TABLE 		Temp_CTSCustID (
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY   	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidence;
    CREATE TEMPORARY TABLE 		Temp_CustomerEvidence (			
			CTSCustID			BIGINT UNSIGNED DEFAULT 0
		,	CustID 				BIGINT UNSIGNED
		,	EvidenceID			SMALLINT UNSIGNED
        , 	PRIMARY KEY     	PK_Temp_CustomerEvidence_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
	);   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClass;
    CREATE TEMPORARY TABLE 		Temp_ExistedClass (			
			CTSCustID			BIGINT UNSIGNED DEFAULT 0
		,	CustID 				BIGINT UNSIGNED
		,	EvidenceID			SMALLINT UNSIGNED
        ,	CategoryID			SMALLINT UNSIGNED
        , 	PRIMARY KEY     	PK_Temp_ExistedClass(CustID,CategoryID)
	);   
        
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CTSCustID (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
	INSERT INTO Temp_CustomerID(CTSCustID, CustID)
    SELECT  t.CTSCustID
		,	c.CustID
	FROM Temp_CTSCustID AS t
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID;
    
    INSERT INTO Temp_CustomerEvidence(CTSCustID,CustID,EvidenceID)
    SELECT	DISTINCT 
			e.CTSCustID
		,	t.CustID
		,	e.EvidenceID
    FROM CTS_DataCenter.CustEvidence AS e
		INNER JOIN Temp_CustomerID AS t ON e.CTSCustID = t.CTSCustID
	WHERE e.Level = 0;
    
    /* Delete customer's flagged evidences */
    DELETE e
    FROM CTS_DataCenter.CustEvidence AS e
		INNER JOIN Temp_CustomerID AS t ON e.CTSCustID = t.CTSCustID
	WHERE e.Level = 0;
    
    /* Delete associated customer's evidences */
   INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID)
   SELECT 	ev.CTSCustID
   FROM Temp_CustomerID AS ev;

	/* Remove relevant category */
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Category
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;    
    
	IF (lv_IsSyncEvi2Category = '1') THEN
		/*	IGNORE PIN CATEGORY	*/
        DELETE t
        FROM Temp_CustomerEvidence AS t
			INNER JOIN CTS_DataCenter.PinCustomerCategory AS p ON t.CTSCustID = p.CTSCustID;
            
		INSERT IGNORE INTO Temp_ExistedClass(CTSCustID,CustID,EvidenceID,CategoryID)
        SELECT 	clss.CTSCustID
			,	clss.CustID
            ,	tmp.EvidenceID
            ,	clss.CategoryID
        FROM CTS_DataCenter.CTSCustomerClassification AS clss       
		INNER JOIN  Temp_CustomerEvidence AS tmp ON tmp.CustID = clss.CustID 
		INNER JOIN  CTS_DataCenter.CustomerCategory AS cate ON (cate.EvidenceID_Licensee = tmp.EvidenceID OR cate.EvidenceID_Credit = tmp.EvidenceID) 
																AND cate.SourceType = 'Evidence' 
																AND clss.CategoryID = cate.CategoryID; 
		DELETE  clss
		FROM CTS_DataCenter.CTSCustomerClassification AS clss       
		INNER JOIN  Temp_ExistedClass AS tmp ON  clss.CustID = tmp.CustID AND clss.CategoryID = tmp.CategoryID; 
            
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT t.CustID
			, 	t.CTSCustID
			, 	ec.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	2
			, 	1
			, 	DATE(lv_CurrentDateTime)
			, 	-1
			, 	9
			,   1
		FROM Temp_CustomerEvidence AS t             
			INNER JOIN Temp_ExistedClass AS ec ON t.EvidenceID = ec.EvidenceID;

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT t.CustID
			, 	t.CTSCustID
			, 	ec.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	2
			, 	1
			, 	DATE(lv_CurrentDateTime)
			, 	-1
			, 	9
			,   1
		FROM Temp_CustomerEvidence AS t             
			INNER JOIN Temp_ExistedClass AS ec ON t.EvidenceID = ec.EvidenceID;
                
        SELECT GROUP_CONCAT(DISTINCT CustID SEPARATOR ', ')
        INTO op_Result
		FROM Temp_CustomerEvidence;
    END IF;
     
    DROP TEMPORARY TABLE Temp_CustomerID;
    DROP TEMPORARY TABLE Temp_CustomerEvidence;
END$$

DELIMITER ;