/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetTaggingByAssociationWithPA`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetTaggingByAssociationWithPA`(
		IN ip_ListCustID	TEXT
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
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetTaggingByAssociationWithPA('1268,38665541,17004');
	*/

    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE 		Temp_Customer (
			CustID 				BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        ,   TaggingID 			INT DEFAULT NULL
        ,	TaggingType			SMALLINT DEFAULT 1
        , 	PRIMARY KEY     	PK_Temp_Dev_CTSCustID_CustID(CTSCustID,CustID)
        ,   KEY     			PK_Temp_Dev_CustID(CustID)
	);   
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE 		Temp_CustAssociation (
			CustID 			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED 
        ,   CTSCustID_Aff 	BIGINT UNSIGNED 
        , 	PRIMARY KEY 	PK_Temp_Dev_CTSCustID_CustID(CTSCustID_Aff, CustID, CTSCustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociationPA;
    CREATE TEMPORARY TABLE 		Temp_CustAssociationPA (
			CustID 			BIGINT UNSIGNED
		,	TaggingID		INT  
        , 	PRIMARY KEY 	PK_Temp_AssociationPA_CustID(CustID)
	);  

    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_ListCustID, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    UPDATE Temp_Customer  AS tbl 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tbl.CustID = cus.CustID AND cus.CustSubID = 0
	SET tbl.CTSCustID = cus.CTSCustID;
    
    UPDATE Temp_Customer  AS tbl 
		INNER JOIN CTS_DataCenter.TaggingExclusion AS mar ON tbl.CustID = mar.CustID
	SET tbl.TaggingType = 0;
    
	INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
	SELECT 
			cus.CustID
        , 	cus.CTSCustID
        , 	asCus.CTSCustID  
	FROM Temp_Customer AS cus 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON asDv .CTSCustID =  cus.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  AND asCus.CTSCustID  !=   asDv.CTSCustID;
    
	INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
	SELECT 
			cus.CustID
        , 	cus.CTSCustID
        , 	asMa.ToCTSCustID  
	FROM Temp_Customer AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS asMa ON asMa.FromCTSCustID =  cus.CTSCustID;
    
    DELETE cuAs FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe 
			ON (cuAs.CTSCustID = asRe.FromCTSCustID AND cuAs.CTSCustID_Aff = asRe.ToCTSCustID) OR (cuAs.CTSCustID_Aff = asRe.ToCTSCustID AND cuAs.CTSCustID = asRe.FromCTSCustID);
    
    INSERT INTO Temp_CustAssociationPA (CustID, TaggingID)
	WITH CTE_Result AS (      
		SELECT
			tbl2.CustID
		, 	tbl2.CTSCustID
		,   COUNT(*) AS Total
		,	GROUP_CONCAT( DISTINCT tbl2.CustomerClass SEPARATOR  ',') AS CustomerClassStr
        FROM (
				SELECT 
						tbl.CustID
					, 	tbl.CTSCustID
					,	tbl.CTSCustID_Aff
					,	CASE	WHEN GROUP_CONCAT(CustomerClass SEPARATOR  ',') LIKE '%10%' THEN 10
								WHEN GROUP_CONCAT(CustomerClass SEPARATOR  ',') LIKE '%8%' THEN 8
								WHEN GROUP_CONCAT(CustomerClass SEPARATOR  ',') LIKE '%13%' THEN 13
						END AS 	CustomerClass 
				FROM(
					SELECT 
							cus.CustID
						, 	cus.CTSCustID
						, 	cus.CTSCustID_Aff 
						, 	CASE	WHEN class.CustomerClass IS NOT NULL THEN class.CustomerClass
									ELSE  spCu.CustomerClass
							END CustomerClass 
					FROM Temp_CustAssociation AS cus 
						LEFT JOIN  CTS_DataCenter.SpecialCustomerClass AS spCu ON spCu.CTSCustID  =  cus.CTSCustID_Aff AND spCu.CustomerClass = 13
						LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CTSCustID = cus.CTSCustID_Aff AND SportGroupID = 0
						LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS class ON class.CategoryID =  cc.CategoryID 
					WHERE 	class.CustomerClass = 8 
							OR 	class.CustomerClass = 10 
							OR 	spCu.CTSCustID IS NOT NULL			
				) AS tbl
				GROUP BY tbl.CustID, tbl.CTSCustID, tbl.CTSCustID_Aff
        ) AS tbl2
        GROUP BY tbl2.CustID, tbl2.CTSCustID
	)
    SELECT 	CustID
		,	CASE	WHEN CustomerClassStr LIKE '%10%' THEN 10
					WHEN CustomerClassStr LIKE '%8%' THEN 8
					WHEN CustomerClassStr LIKE '%13%' THEN 13
			END AS 	CustomerClass
	FROM CTE_Result 
	WHERE CTE_Result.Total > 2;
	
    UPDATE Temp_Customer AS cus
    INNER JOIN Temp_CustAssociationPA AS pa ON cus.CustID = pa.CustID
    SET cus.TaggingID = pa.TaggingID;
    
    SELECT CustID, TaggingID, TaggingType
    FROM Temp_Customer;
END$$

DELIMITER ;