/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DangerLevel_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_DangerLevel_Get`(
		IN ip_CustIDs 	TEXT
    ,	IN ip_TypeID 	SMALLINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210401@Irena.Vo
		Task:		Get Danger Level for customers
		DB:			CTS_DataCenter 
		Original:
		Revisions:
			- 20210401@Irena.Vo: Created [Redmine ID: #152249]
			- 20210524@Aries.Nguyen: Enhance performance  [Redmine ID: #155693]

		Param's Explanation (filtered by):
			- ip_CustIDs ; ip_TypeID: 1(Original) / 2(ABI) / 3(Other)
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_DangerLevel_Get('36266996,27852979,2324948',1);
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
    CREATE TEMPORARY TABLE Temp_Customers (
			CustID 		BIGINT UNSIGNED PRIMARY KEY
        ,	HistoryID 	BIGINT UNSIGNED
    );  
    
    -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
    -- Get lastest history (Ass with PA & Have change Category)
    UPDATE Temp_Customers AS temp
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 200
		STRAIGHT_JOIN CTS_DataCenter.TaggingToCategory AS tag ON tag.CategoryID = cate.CategoryID
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.CustID = temp.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate = cate.LastModifiedDate
	SET 	temp.HistoryID = his.ID
	WHERE 	tag.TaggingID <> 0 AND his.IsDataChanged = 1 AND his.ToCategoryID <> IFNULL(his.FromCategoryID,0);
    
    -- Get Results.
    IF (ip_TypeID = 1) THEN -- Original
		SELECT temp.CustId, his.LastModifiedDate AS ScannedTime, his.TargetDangerLevel1 AS DangerLevel
		FROM Temp_Customers AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.ID = temp.HistoryID
        WHERE his.TargetDangerLevel1 IS NOT NULL;
	END IF;
   /* IF (ip_TypeID = 2) THEN -- ABI
		SELECT temp.CustId, his.LastModifiedDate AS ScannedTime, his.TargetDangerLevel2 AS DangerLevel
		FROM Temp_Customers AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.ID = temp.HistoryID
        WHERE his.TargetDangerLevel2 IS NOT NULL;
	END IF;
    IF (ip_TypeID = 3) THEN -- Other
		SELECT temp.CustId, his.LastModifiedDate AS ScannedTime, his.TargetDangerLevel3 AS DangerLevel
		FROM Temp_Customers AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.ID = temp.HistoryID
        WHERE his.TargetDangerLevel3 IS NOT NULL;
	END IF; */
END$$
DELIMITER ;