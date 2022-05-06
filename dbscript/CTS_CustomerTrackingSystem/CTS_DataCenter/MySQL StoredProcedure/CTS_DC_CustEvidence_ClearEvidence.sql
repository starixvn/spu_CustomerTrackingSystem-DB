/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_ClearEvidence`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_ClearEvidence`(
		IN ip_CustJson 				JSON
    
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
            - 20220426@Casey.Huynh: Add CreatedBy [Redmine ID: #171512]
            
		Param's Explanation (filtered by):   
			- ActionID: 1 insert, 2 override, 3 clear
            
		Example:			
			- CALL CTS_DataCenter.CTS_DC_CustEvidence_ClearEvidence('5940,40290236', 8, @op_ErrorMessage, @op_Result);
	*/
        
    DECLARE	lv_CurrentDateTime 		DATETIME DEFAULT CURRENT_TIME();
    DECLARE	lv_IsSyncEvi2Category 	VARCHAR(1) DEFAULT '';  
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCustList;
    CREATE TEMPORARY TABLE 	Temp_InputCustList (
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		,	RemoveBy		INT	UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerID;
    CREATE TEMPORARY TABLE 		Temp_CustomerID (
			CustID 				BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        ,	RemoveBy			INT	UNSIGNED
        , 	PRIMARY KEY     	PK_Temp_CustomerID_CTSCustID_CustID(CTSCustID,CustID)
	);  
	
	
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidence;
    CREATE TEMPORARY TABLE 		Temp_CustomerEvidence (			
			CTSCustID			BIGINT UNSIGNED DEFAULT 0
		,	CustID 				BIGINT UNSIGNED
		,	EvidenceID			SMALLINT UNSIGNED
        ,	RemoveBy			INT	UNSIGNED
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
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences 
	(	 
			CTSCustID		BIGINT UNSIGNED
        ,	EvidenceID		SMALLINT UNSIGNED
        ,	Remark			VARCHAR(500)
        ,	RemoveBy		INT UNSIGNED
        
		, 	INDEX	IX_Temp_CustomerEvidences_CTSCustID_EvidenceID(CTSCustID,EvidenceID) 
	);      
    
    INSERT INTO Temp_InputCustList(CTSCustID, RemoveBy)
	SELECT	tmpTable.CTSCustID
		,	tmpTable.RemoveBy
	FROM JSON_TABLE(ip_CustJson, 
		"$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
            , RemoveBy		INT UNSIGNED		PATH "$.CreatedBy"
		)) AS tmpTable;	
    
	INSERT INTO Temp_CustomerID(CTSCustID, CustID, RemoveBy)
    SELECT  t.CTSCustID
		,	c.CustID
        ,	t.RemoveBy
	FROM Temp_InputCustList AS t
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID;
  
    INSERT INTO Temp_CustomerEvidence(CTSCustID,CustID,EvidenceID, RemoveBy)
    SELECT	DISTINCT 
			e.CTSCustID
		,	t.CustID
		,	e.EvidenceID
        ,	t.RemoveBy
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

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate
				, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT t.CustID
			, 	t.CTSCustID
			, 	ec.CategoryID
			, 	0 AS SportGroupID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	t.RemoveBy AS LastModifiedBy
			, 	2 AS ActionType
			, 	1 AS IsAuto
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			, 	-1 AS TargetCC
			, 	9 AS SourceTypeID
			,   1 AS IsDataChanged
		FROM Temp_CustomerEvidence AS t             
			INNER JOIN Temp_ExistedClass AS ec ON t.EvidenceID = ec.EvidenceID;

		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT t.CustID
			, 	t.CTSCustID
			, 	ec.CategoryID
			, 	0 AS SportGroupID
			, 	lv_CurrentDateTime
			, 	t.RemoveBy AS CreatedBy
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

END$$

DELIMITER ;