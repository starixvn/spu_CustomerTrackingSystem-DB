/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetTaggingByAssociationWithPA`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_GetTaggingByAssociationWithPA`(
	IN ip_ListCustID		TEXT 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210122@Aries.Nguyen
		Task:		Get Tagging association problem account
		DB:			CTS_DataCenter
		Original:
		Revisions:
		   - 20210226@Aries.Nguyen: Created [Redmine ID: #148908]
           - 20210416@Irena.Vo: Update source get Robot User & ignore sub ass acc [Redmine ID: #15250] 
		   - 20210427@Aries.Nguyen: Enhance performance [Redmine ID: #152509] 
		   - 20210525@Irena.Vo: Change col name TaggingExclusion: CustID -> CTSCustID [Redmine ID: 152965]
		   - 20210722@Long.Luu: Refactor  [Redmine ID: #157203]
           - 20210804@Irena.Vo: Fix issue get Duplicate list Association Remove [Redmine ID: #159706]
		   - 20210818@Aries.Nguyen: Exclude Unlink association [Redmine ID: #159708]
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetTaggingByAssociationWithPA('1268,38665541,17004,32339123379301,3481646');
	*/
	
    DECLARE	CONST_CATEGORYID_ROBOTUSERS 	INT DEFAULT 61;
    DECLARE	CONST_GROUP_PA 					INT DEFAULT 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomers;
    CREATE TEMPORARY TABLE 	Temp_InputCustomers (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
        ,   CTSCustID		BIGINT UNSIGNED DEFAULT 0
	);   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE 	Temp_Customer (
			CustID 			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED
        ,   TaggingID 		INT DEFAULT NULL
        ,	TaggingType		SMALLINT DEFAULT 1
        , 	PRIMARY KEY     PK_Temp_Dev_CTSCustID_CustID(CTSCustID,CustID)
        ,   KEY     		PK_Temp_Dev_CustID(CustID)
	);   
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE 	Temp_CustAssociation (
			CustID 			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED 
        ,   CTSCustID_Aff 	BIGINT UNSIGNED 
        , 	PRIMARY KEY 	PK_Temp_Dev_CTSCustID_CustID(CTSCustID_Aff, CustID, CTSCustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociationPA;
    CREATE TEMPORARY TABLE 	Temp_CustAssociationPA (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
		,	TaggingID		INT
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLevel1;
    CREATE TEMPORARY TABLE 	Temp_CustLevel1 (			
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PA;
    CREATE TEMPORARY TABLE 	Temp_PA (			
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		,	CustomerClass	INT DEFAULT 0
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SubAccounts;
    CREATE TEMPORARY TABLE 	Temp_SubAccounts (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationRemoveAccounts;
    CREATE TEMPORARY TABLE 	Temp_AssociationRemoveAccounts (
			FromCTSCustID 	BIGINT UNSIGNED
		,	ToCTSCustID		BIGINT UNSIGNED
        ,	PRIMARY KEY 	PK_Temp_AssociationRemoveAccounts (FromCTSCustID,ToCTSCustID)
        ,	KEY				IX_Temp_AssociationRemoveAccounts_ToCTSCustID (ToCTSCustID)
	); 
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_InputCustomers (CustID) VALUES ('", REPLACE(ip_ListCustID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    INSERT INTO Temp_Customer(CustID, CTSCustID)
    SELECT temp.CustID, cus.CTSCustID
    FROM Temp_InputCustomers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON temp.CustID = cus.CustID AND cus.CustSubID = 0;
    
	UPDATE Temp_Customer  AS tbl 
		INNER JOIN CTS_DataCenter.TaggingExclusion AS mar ON tbl.CTSCustID = mar.CTSCustID
	SET tbl.TaggingType = 0;
    
	INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
	SELECT 	cus.CustID, cus.CTSCustID, asCus.CTSCustID  
	FROM 	Temp_Customer AS cus 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON asDv.CTSCustID = cus.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID = asDv.DCSDeviceID AND asCus.CTSCustID <> asDv.CTSCustID
	WHERE 	cus.TaggingType = 1;
    
	INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
	SELECT 	cus.CustID, cus.CTSCustID, asMa.ToCTSCustID  
	FROM 	Temp_Customer AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS asMa ON asMa.FromCTSCustID = cus.CTSCustID
	WHERE 	cus.TaggingType = 1;
    
    INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
    SELECT 	cus.CustID, cus.CTSCustID, asMa.FromCTSCustID  
    FROM 	Temp_Customer AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS asMa ON asMa.ToCTSCustID = cus.CTSCustID
    WHERE 	cus.TaggingType = 1;

	INSERT INTO Temp_SubAccounts(CTSCustID)
    SELECT DISTINCT cus.CTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cuAs.CustID = cus.CustID AND cus.CustSubID <> 0;
        
    DELETE cuAs FROM Temp_CustAssociation AS cuAs
		INNER JOIN Temp_SubAccounts AS cus ON cuAs.CTSCustID = cus.CTSCustID;
  
    INSERT INTO Temp_AssociationRemoveAccounts(FromCTSCustID,ToCTSCustID)
    SELECT DISTINCT asRe.FromCTSCustID, asRe.ToCTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON cuAs.CTSCustID_Aff = asRe.ToCTSCustID AND cuAs.CTSCustID = asRe.FromCTSCustID;

	INSERT INTO Temp_AssociationRemoveAccounts(FromCTSCustID,ToCTSCustID)
    SELECT DISTINCT asRe.FromCTSCustID, asRe.ToCTSCustID
    FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON cuAs.CTSCustID = asRe.ToCTSCustID AND cuAs.CTSCustID_Aff = asRe.FromCTSCustID
	
    DELETE cuAs 
	FROM Temp_CustAssociation AS cuAs
		INNER JOIN Temp_AssociationRemoveAccounts AS asRe ON (cuAs.CTSCustID = asRe.FromCTSCustID AND cuAs.CTSCustID_Aff = asRe.ToCTSCustID) 
														  OR (cuAs.CTSCustID_Aff = asRe.FromCTSCustID AND cuAs.CTSCustID = asRe.ToCTSCustID);
	
    INSERT INTO Temp_CustLevel1(CTSCustID)
    SELECT DISTINCT CTSCustID_Aff AS Level1  
    FROM 	Temp_CustAssociation;
    
    INSERT INTO Temp_PA(CTSCustID, CustomerClass)
    SELECT 	cus.CTSCustID, class.CustomerClass
	FROM 	Temp_CustLevel1 AS cus
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CTSCustID = cus.CTSCustID AND SportGroupID = CONST_GROUP_PA
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS class ON class.CategoryID =  cc.CategoryID
    WHERE 	cc.CategoryID = CONST_CATEGORYID_ROBOTUSERS OR class.CustomerClass IN (8, 10)
    ON DUPLICATE KEY UPDATE CustomerClass = CASE WHEN class.CustomerClass = 10 THEN 10
												 WHEN class.CustomerClass = 8 AND Temp_PA.CustomerClass <> 10 THEN 8
											END;
    
    INSERT INTO Temp_CustAssociationPA (CustID, TaggingID)
    WITH CTE_Result AS (      
		SELECT	cus.CustID
			, 	cus.CTSCustID
			,   COUNT(*) AS Total
			,	GROUP_CONCAT( DISTINCT pa.CustomerClass SEPARATOR  ',') AS CustomerClassStr
        FROM 	Temp_CustAssociation AS cus
			INNER JOIN Temp_PA AS pa ON cus.CTSCustID_Aff = pa.CTSCustID
        GROUP BY 	cus.CustID, cus.CTSCustID
	)
    SELECT 	CustID
		,	CASE 	WHEN CustomerClassStr LIKE '%10%' THEN 10
					WHEN CustomerClassStr LIKE '%8%' THEN 8
					WHEN CustomerClassStr LIKE '%13%' THEN 13
			END AS CustomerClass
	FROM 	CTE_Result 
	WHERE 	CTE_Result.Total > 2;
	
    UPDATE 	Temp_Customer AS cus
		INNER JOIN Temp_CustAssociationPA AS pa ON cus.CustID = pa.CustID
    SET 	cus.TaggingID = pa.TaggingID;
    
    SELECT CustID, TaggingID, TaggingType 
    FROM Temp_Customer;
    
END$$
DELIMITER ;