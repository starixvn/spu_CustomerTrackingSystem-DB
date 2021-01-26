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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ListCustDev;
    CREATE TEMPORARY TABLE 		Temp_ListCustDev (
			CustID 		BIGINT UNSIGNED
		,	CTSCustID	BIGINT UNSIGNED 
        KEY
	);   
	
    DROP TEMPORARY TABLE IF EXISTS Temp_ListCustManual;
    CREATE TEMPORARY TABLE 		Temp_ListCustManual (
			CustID 		BIGINT UNSIGNED
		,	CTSCustID	BIGINT UNSIGNED 
		, 	PRIMARY KEY     	PK_Temp_CTSCustID_CustID(CTSCustID,CustID)      
	);  

    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_ListCustDev (CustID) VALUES ('", REPLACE(ip_ListCustID, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    UPDATE Temp_ListCustDev  AS tbl 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tbl.CustID = cus.CustID
	SET tbl.CTSCustID = cus.CTSCustID;
    
    INSERT INTO Temp_ListCustManual(CTSCustID, CustID)
    SELECT CTSCustID, CustID 
    FROM Temp_ListCustDev;
    
	WITH CTE_Result AS (      
		SELECT 
				tbl.CustID
			, 	tbl.CTSCustID
			,   COUNT(*) AS Total
			,	GROUP_CONCAT( DISTINCT CustomerClass SEPARATOR  ',') AS CustClass
		FROM(
			SELECT 
					cus.CustID
				, 	cus.CTSCustID
                , 	asCus.CTSCustID AS CTSCustID_Aff
                , 	CASE	WHEN class.CustomerClass IS NOT NULL THEN class.CustomerClass
							ELSE  spCu.CustomerClass
					END CustomerClass
			FROM Temp_ListCustDev AS cus 
				INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON asDv .CTSCustID =  cus.CTSCustID
				INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  AND asCus.CTSCustID  !=   asDv.CTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = asDv.CTSCustID AND  asRe.ToCTSCustID =  asCus.CTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe1 ON asRe1.FromCTSCustID =  asCus.CTSCustID AND asRe1.ToCTSCustID = asDv.CTSCustID 
                LEFT JOIN  CTS_DataCenter.SpecialCustomerClass AS spCu ON spCu.CTSCustID =  asCus.CTSCustID AND spCu.CustomerClass = 13
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CTSCustID = asCus.CTSCustID AND SportGroupID = 0
				LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS class ON class.CategoryID =  cc.CategoryID 
			WHERE 	asRe.FromCTSCustID IS NULL 
				AND asRe1.FromCTSCustID IS NULL 
                AND (	class.CustomerClass = 8 
					OR 	class.CustomerClass = 10 
                    OR 	spCu.CTSCustID IS NOT NULL
				)
        
			UNION
    
			SELECT 
					cus.CustID
				, 	cus.CTSCustID
                , 	asMa.ToCTSCustID AS CTSCustID_Aff
                , 	CASE	WHEN class.CustomerClass IS NOT NULL THEN class.CustomerClass
							ELSE  spCu.CustomerClass
					END CustomerClass
			FROM Temp_ListCustManual AS cus
				INNER JOIN CTS_DataCenter.AssociationByManual AS asMa ON asMa.FromCTSCustID =  cus.CTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = asMa.FromCTSCustID AND  asRe.ToCTSCustID =  asMa.ToCTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe1 ON asRe1.FromCTSCustID =  asMa.ToCTSCustID AND asRe1.ToCTSCustID = asMa.FromCTSCustID
                LEFT JOIN  CTS_DataCenter.SpecialCustomerClass AS spCu ON spCu.CTSCustID =  asMa.FromCTSCustID AND spCu.CustomerClass = 13
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CTSCustID = asMa.ToCTSCustID AND SportGroupID = 0
				LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS class ON class.CategoryID =  cc.CategoryID
			WHERE 	asRe.FromCTSCustID IS NULL 
				AND asRe1.FromCTSCustID IS NULL
                AND (	class.CustomerClass = 8 
					OR 	class.CustomerClass = 10 
                    OR 	spCu.CTSCustID IS NOT NULL
				)
		) AS tbl
		GROUP BY tbl.CustID, tbl.CTSCustID
	)
	SELECT 	CustID
		,	CTSCustID
		,	CASE	WHEN CustClass LIKE '%10%' THEN 232
					WHEN CustClass LIKE '%8%' THEN 231
					WHEN CustClass LIKE '%13%' THEN 233
			END AS 	CategoryID
	FROM CTE_Result 
	WHERE CTE_Result.Total > 2;
END$$

DELIMITER ;