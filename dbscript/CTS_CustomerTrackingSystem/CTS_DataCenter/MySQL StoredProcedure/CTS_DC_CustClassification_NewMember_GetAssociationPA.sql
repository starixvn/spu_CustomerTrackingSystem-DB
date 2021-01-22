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
			- CALL CTS_DataCenter.CTS_DC_CustClassification_NewMember_GetAssociationPA('2010792,26722833,26722689,26722424,42612948,43600693', @err);

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

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CustClassification_NewMember_GetAssociationPA',op_ErrorMessage, JSON_OBJECT('parameter', ip_CustIDList));
    
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
			SELECT cus.CustID, cus.CTSCustID, asCus.CTSCustID AS CTSCustID_Aff, class.CustomerClass
			FROM Temp_ListCustDev as cus 
				INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON asDv .CTSCustID =  cus.CTSCustID
				INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  and asCus.CTSCustID  !=   asDv.CTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = asDv.CTSCustID and  asRe.ToCTSCustID =  asCus.CTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe1 ON asRe1.FromCTSCustID =  asCus.CTSCustID and asRe1.ToCTSCustID = asDv.CTSCustID 
				LEFT JOIN  CTS_DataCenter.CustException AS cuEx ON (cuEx.FromCTSCustID = asDv.CTSCustID AND cuEx.ToCTSCustID =  asCus.CTSCustID)
				LEFT JOIN  CTS_DataCenter.CustException AS cuEx1 ON (cuEx1.FromCTSCustID = asCus.CTSCustID AND cuEx1.ToCTSCustID =  asDv.CTSCustID)
				INNER JOIN CTS_DataCenter.CTSCustomerClassification as cc on cc.CTSCustID = asCus.CTSCustID and SportGroupID = 0
				INNER JOIN CTS_DataCenter.CategoryToCustomerClass as class on class.CategoryID =  cc.CategoryID and class.CustomerClass in (8,10,13)
			WHERE asRe.FromCTSCustID IS NULL AND cuEx.FromCTSCustID IS  NULL AND   asRe1.FromCTSCustID IS NULL AND cuEx1.FromCTSCustID  IS NULL
        
			UNION
    
			SELECT cus.CustID, cus.CTSCustID, asMa.ToCTSCustID AS CTSCustID_Aff, class.CustomerClass
			FROM Temp_ListCustManual as cus
				INNER JOIN CTS_DataCenter.AssociationByManual AS asMa ON asMa.FromCTSCustID =  cus.CTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = asMa.FromCTSCustID and  asRe.ToCTSCustID =  asMa.ToCTSCustID
				LEFT JOIN  CTS_DataCenter.AssociationRemove AS asRe1 ON asRe1.FromCTSCustID =  asMa.ToCTSCustID and asRe1.ToCTSCustID = asMa.FromCTSCustID 
				LEFT JOIN  CTS_DataCenter.CustException AS cuEx ON (cuEx.FromCTSCustID = asMa.FromCTSCustID AND cuEx.ToCTSCustID =  asMa.ToCTSCustID)
				LEFT JOIN  CTS_DataCenter.CustException AS cuEx1 ON (cuEx1.FromCTSCustID =   asMa.ToCTSCustID AND cuEx1.ToCTSCustID =  asMa.FromCTSCustID)
				INNER JOIN CTS_DataCenter.CTSCustomerClassification as cc on cc.CTSCustID = asMa.ToCTSCustID and SportGroupID = 0
				INNER JOIN CTS_DataCenter.CategoryToCustomerClass as class on class.CategoryID =  cc.CategoryID and class.CustomerClass in (8,10,13)
			WHERE asRe.FromCTSCustID IS  NULL AND cuEx.FromCTSCustID IS  NULL AND  cuEx1.FromCTSCustID IS NULL AND cuEx1.FromCTSCustID  IS NULL
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