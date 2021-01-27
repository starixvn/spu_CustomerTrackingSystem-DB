/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_NewMember_GetAssociationPA`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_NewMember_GetAssociationPA`(
		IN ip_ListCustID	TEXT
        
    ,	OUT op_ErrorMessage VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210122@Aries.Nguyen
		Task:		Get new member association problem account
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210122@Aries.Nguyen: Created [Redmine ID: #148908]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_NewMember_GetAssociationPA('1268,38665541,17004', @error);
	*/
	DECLARE	lv_No INT DEFAULT 1;
	DECLARE op_ErrorMessage2 VARCHAR(200) DEFAULT '';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No = NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage = MESSAGE_TEXT;	
		
		IF(lv_No > 1) THEN
			SET lv_No = lv_No - 1;
			GET STACKED  DIAGNOSTICS CONDITION lv_No
				op_ErrorMessage2 = MESSAGE_TEXT;	
        END IF;
			
		SET op_ErrorMessage = CONCAT(op_ErrorMessage,'; ',op_ErrorMessage2);

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CustClassification_NewMember_GetAssociationPA',op_ErrorMessage, JSON_OBJECT('parameter', ip_ListCustID));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = op_ErrorMessage;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerIDs;
    CREATE TEMPORARY TABLE 		Temp_CustomerIDs (
			CustID 		BIGINT UNSIGNED
		,	CTSCustID	BIGINT UNSIGNED DEFAULT 0
        , 	PRIMARY KEY     	PK_Temp_Dev_CTSCustID_CustID(CTSCustID,CustID)
	);   
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE 		Temp_CustAssociation (
			CustID 			BIGINT UNSIGNED
		,	CTSCustID		BIGINT UNSIGNED 
        ,   CTSCustID_Aff 	BIGINT UNSIGNED 
        , 	PRIMARY KEY 	PK_Temp_Dev_CTSCustID_CustID(CTSCustID_Aff, CustID, CTSCustID)
	);  

    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustomerIDs (CustID) VALUES ('", REPLACE(ip_ListCustID, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    UPDATE Temp_CustomerIDs  AS tbl 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tbl.CustID = cus.CustID AND cus.CustSubID = 0
	SET tbl.CTSCustID = cus.CTSCustID;
    
    
	INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
	SELECT 
			cus.CustID
        , 	cus.CTSCustID
        , 	asCus.CTSCustID  
	FROM Temp_CustomerIDs AS cus 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON asDv .CTSCustID =  cus.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  AND asCus.CTSCustID  !=   asDv.CTSCustID;
    
    
	INSERT IGNORE INTO Temp_CustAssociation(CustID, CTSCustID, CTSCustID_Aff)
	SELECT 
			cus.CustID
        , 	cus.CTSCustID
        , 	asMa.ToCTSCustID  
	FROM Temp_CustomerIDs AS cus 
		INNER JOIN CTS_DataCenter.AssociationByManual AS asMa ON asMa.FromCTSCustID =  cus.CTSCustID;
    
    DELETE cuAs FROM Temp_CustAssociation AS cuAs
		INNER JOIN CTS_DataCenter.AssociationRemove AS asRe 
			ON (cuAs.CTSCustID = asRe.FromCTSCustID AND cuAs.CTSCustID_Aff = asRe.ToCTSCustID) OR (cuAs.CTSCustID_Aff = asRe.ToCTSCustID AND cuAs.CTSCustID = asRe.FromCTSCustID);
    
	WITH CTE_Result AS (      
		SELECT
			tbl2.CustID
		, 	tbl2.CTSCustID
		,   COUNT(*) AS Total
		,	GROUP_CONCAT( DISTINCT tbl2.CategoryID SEPARATOR  ',') AS CategoryStr
        FROM (
				SELECT 
						tbl.CustID
					, 	tbl.CTSCustID
					,	tbl.CTSCustID_Aff
					,	CASE	WHEN GROUP_CONCAT(CustomerClass SEPARATOR  ',') LIKE '%10%' THEN 232
								WHEN GROUP_CONCAT(CustomerClass SEPARATOR  ',') LIKE '%8%' THEN 231
								WHEN GROUP_CONCAT(CustomerClass SEPARATOR  ',') LIKE '%13%' THEN 233
						END AS 	CategoryID 
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
		,	CTSCustID
		,	CASE	WHEN CategoryStr LIKE '%232%' THEN 232
					WHEN CategoryStr LIKE '%231%' THEN 231
					WHEN CategoryStr LIKE '%233%' THEN 233
			END AS 	CategoryID
	FROM CTE_Result 
	WHERE CTE_Result.Total > 2;

END$$

DELIMITER ;