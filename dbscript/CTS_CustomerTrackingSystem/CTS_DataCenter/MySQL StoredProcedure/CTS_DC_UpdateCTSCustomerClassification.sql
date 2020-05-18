DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_UpdateCTSCustomerClassification`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_UpdateCTSCustomerClassification`(
		IN ip_CTSCustID			BIGINT UNSIGNED
    ,	IN ip_SubscriberID		INT
	,	IN ip_CategoryID		SMALLINT
    , 	IN ip_SportGroupIDList 	VARCHAR(50)
    , 	IN ip_Remark 			VARCHAR(300)
	,	IN ip_CreatedBy 		INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS tempSportGroupID;
    CREATE TEMPORARY TABLE tempSportGroupID (
			SportGroupID 		INT PRIMARY KEY
        ,	ActionStatus		BIT DEFAULT 0 # 0: insert, 1: update
    );
    
	SET @sql = CONCAT("INSERT INTO tempSportGroupID (SportGroupID) VALUES ('", REPLACE(ip_SportGroupIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SET SQL_SAFE_UPDATES = 0;
    UPDATE tempSportGroupID AS s
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS t ON t.SportGroupID = s.SportGroupID AND t.CategoryID = ip_CategoryID
	SET s.ActionStatus = 1
    WHERE t.CTSCustID = ip_CTSCustID;
    
    DELETE t
    FROM CTS_DataCenter.CTSCustomerClassification AS t
		LEFT JOIN tempSportGroupID AS s ON t.SportGroupID = s.SportGroupID
    WHERE t.CTSCustID = ip_CTSCustID
		AND t.CategoryID = ip_CategoryID
        AND s.SportGroupID IS NULL;
    
    UPDATE 	CTS_DataCenter.CTSCustomerClassification AS t
		INNER JOIN tempSportGroupID AS s ON t.SportGroupID = s.SportGroupID AND t.CategoryID = ip_CategoryID
    SET 	t.Remark = ip_Remark
        ,	t.LastModifiedBy = ip_CreatedBy
		,	t.LastModifiedDate = CURRENT_TIME()
	WHERE t.CTSCustID = ip_CTSCustID
		AND s.ActionStatus = 1;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
	INSERT INTO CTS_DataCenter.CTSCustomerClassification(CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
	SELECT 	ip_CTSCustID
		, 	ip_SubscriberID
        , 	ip_CategoryID
        , 	s.SportGroupID
        , 	ip_Remark
        , 	CURRENT_TIME(), ip_CreatedBy, CURRENT_TIME(), ip_CreatedBy
    FROM tempSportGroupID AS s
    WHERE s.ActionStatus = 0;
   
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(11, 'CTS_DC_UpdateCTSCustomerClassification', CONCAT('Update CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID, ';ip_CategoryID_', ip_CategoryID, ';ip_SportGroupIDList_', ip_SportGroupIDList, ';ip_Remark_', ip_Remark,')'), CURRENT_TIME(), ip_CreatedBy);
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$	
DELIMITER ;