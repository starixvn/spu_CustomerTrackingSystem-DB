DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AddCTSCustomerClassification` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_AddCTSCustomerClassification`(
		IN ip_CustID			BIGINT UNSIGNED
	, 	IN ip_CTSCustID			BIGINT UNSIGNED	
    ,	IN ip_SubscriberID		INT
	,	IN ip_CategoryID		SMALLINT
    , 	IN ip_SportGroupIDList 	VARCHAR(50)
    , 	IN ip_Remark 			VARCHAR(300)
	,	IN ip_CreatedBy 		INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
			- 20200608@Casey.Huynh: Add parameter ip_CustID
					+ Remove Category "New Member" if existing
            
		Param's Explanation:
	*/ 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    CALL CTS_DataCenter.CTS_DC_VerifyCTSCustomerClassification(ip_CTSCustID, ip_SubscriberID, ip_CategoryID, @errorMessage);
    
    IF @errorMessage IS NOT NULL THEN
		SET op_ErrorMessage = @errorMessage;
        LEAVE sp;
    END IF;
    
    DROP TEMPORARY TABLE IF EXISTS tempSportGroupID;
    CREATE TEMPORARY TABLE tempSportGroupID (
		SportGroupID INT PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO tempSportGroupID (SportGroupID) VALUES ('", REPLACE(ip_SportGroupIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	IF (SELECT COUNT(1) FROM CTS_DataCenter.CustomerCategory WHERE CategoryID = ip_CategoryID AND IsUsedManually = 0) > 0 THEN		
		SET op_ErrorMessage = 'This Category is not allowed for manually update!!!!';
        LEAVE sp;
    END IF;

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    DELETE 		ccl
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS ccl    
	WHERE		ccl.CategoryID = 2 AND CustID = ip_CustID; 
    
	INSERT INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID,  CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
		, 	ip_SubscriberID
        , 	ip_CategoryID
        , 	s.SportGroupID
        , 	ip_Remark
        , 	CURRENT_TIME(), ip_CreatedBy, CURRENT_TIME(), ip_CreatedBy
    FROM tempSportGroupID AS s;
   
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(10, 'CTS_DC_AddCTSCustomerClassification', CONCAT('Insert CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID, ';ip_CategoryID_', ip_CategoryID, ';ip_SportGroupIDList_', ip_SportGroupIDList, ';ip_Remark_', ip_Remark,')'), CURRENT_TIME(), ip_CreatedBy);
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;
