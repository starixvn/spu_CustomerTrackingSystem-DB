/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_SabaDangerLevel_Scan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_SabaDangerLevel_Scan`(
	   OUT op_LastHistoryID 	BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
sp: BEGIN
	/* 
		Created:	20220818@Aries.Nguyen
		Task :		Customer Class - Update Saba Danger Level
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220818@Aries.Nguyen: Created [Redmine ID: #176224] 
            
        Param's Explanation: 

		Example:
			-CALL CTS_DataCenter.CTS_DC_CustClassification_SabaDangerLevel_Scan(@op_LastHistoryID);

	*/
    DECLARE lv_BatchSize 			INT;

    DECLARE lv_LastHistoryID 		BIGINT UNSIGNED;
    DECLARE lv_NextHistoryID 		BIGINT UNSIGNED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE 	Temp_Cust (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SabaSportType;
    CREATE TEMPORARY TABLE 	Temp_SabaSportType (
			CategoryID 			INT
		,	SportType			INT
        ,	PRIMARY KEY(CategoryID, SportType)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSportType;
    CREATE TEMPORARY TABLE 	Temp_CustSportType (
			CustID 			BIGINT UNSIGNED 
		,	SportType		INT
        ,	PRIMARY KEY(CustID, SportType)
	);
    
    SELECT ParameterValue 
    INTO lv_LastHistoryID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 102;
    
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 105;
	
    SELECT MAX(tbl.ID)
    INTO lv_NextHistoryID
    FROM (SELECT his.ID
		  FROM CTS_DataCenter.CTSCustomerClassification_History AS his
		  WHERE his.ID > lv_LastHistoryID
		  ORDER BY his.ID ASC
		  LIMIT lv_BatchSize) AS tbl;
	
    IF lv_NextHistoryID IS NULL THEN
		SET op_LastHistoryID = lv_LastHistoryID;
        LEAVE sp;
    END IF;
    
    SET op_LastHistoryID = lv_NextHistoryID;
    
	INSERT IGNORE INTO Temp_Cust(CustID)
    SELECT 	his.CustID
	FROM CTS_DataCenter.CTSCustomerClassification_History AS his
	WHERE his.ID > lv_LastHistoryID AND his.ID <= lv_NextHistoryID;
    
    INSERT IGNORE INTO Temp_SabaSportType(CategoryID,SportType)
    SELECT	cate.CategoryID
		, 	tbl.SportType
	FROM CTS_DataCenter.CustomerCategory AS cate
		INNER JOIN JSON_TABLE(cate.SabaSportType, 
						'$[*]' COLUMNS (SportType BIGINT UNSIGNED PATH '$')
		) tbl
	WHERE cate.SabaSportType IS NOT NULL;
    
    INSERT IGNORE INTO Temp_CustSportType(CustID, SportType)
    SELECT 	cus.CustID
		,	tmp.SportType
    FROM Temp_Cust AS cus
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON cus.CustID = clss.clss AND clss.SportGroupID = 0
        LEFT JOIN Temp_SabaSportType AS tmp ON clss.CategoryID = tmp.CategoryID;
    
    SELECT 	cus.CustID
		,	CASE WHEN cus.SportType IS NOT NULL AND dg.SportType IS NULL THEN cus.SportType
				 WHEN cus.SportType IS NULL AND dg.SportType IS NOT NULL THEN dg.SportType
			END AS SportType
        ,	CASE WHEN cus.SportType IS NOT NULL AND dg.SportType IS NULL THEN 1
				  WHEN cus.SportType IS NULL AND dg.SportType IS NOT NULL THEN -1
			END AS Action
    FROM Temp_CustSportType AS cus
		LEFT JOIN CTS_DataCenter.CTSCustomerSabaDangerLevel AS lv ON cus.CustID = lv.CustID
	WHERE cus.SportType = dg.SportType
		OR (cus.SportType IS NOT NULL AND dg.SportType IS NULL)
        OR (cus.SportType IS NULL AND dg.SportType IS NOT NULL);

END$$
DELIMITER ;