/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Update`(
        OUT op_ErrorMessage     VARCHAR(200)

    ,   IN ip_CTSCustID         BIGINT UNSIGNED
    ,   IN ip_CustID            BIGINT
    ,   IN ip_SubscriberID      INT
    ,   IN ip_CategoryID        SMALLINT
    ,   IN ip_SportGroupIDList  VARCHAR(50)
    ,   IN ip_Remark            VARCHAR(300)
    ,   IN ip_CreatedBy         INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
            
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_TIME();
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SportGroupID;
    CREATE TEMPORARY TABLE Temp_SportGroupID (
			SportGroupID 		INT PRIMARY KEY
        ,	ActionStatus		BIT DEFAULT 0 # 0: insert, 1: update
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_SportGroupID (SportGroupID) VALUES ('", REPLACE(ip_SportGroupIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    UPDATE Temp_SportGroupID AS s
	    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS t  ON t.SportGroupID = s.SportGroupID AND t.CategoryID = ip_CategoryID
	SET s.ActionStatus = 1
    WHERE t.CTSCustID = ip_CTSCustID;
    
    DELETE t
    FROM CTS_DataCenter.CTSCustomerClassification AS t
	    LEFT JOIN Temp_SportGroupID AS s  ON t.SportGroupID = s.SportGroupID
    WHERE t.CTSCustID = ip_CTSCustID
		AND t.CategoryID = ip_CategoryID
        AND s.SportGroupID IS NULL;
    
    UPDATE 	CTS_DataCenter.CTSCustomerClassification AS t
	    INNER JOIN Temp_SportGroupID AS s ON t.SportGroupID = s.SportGroupID AND t.CategoryID = ip_CategoryID
    SET 	t.Remark = ip_Remark
        ,	t.LastModifiedBy = ip_CreatedBy
		,	t.LastModifiedDate = lv_CurrentTime
	WHERE t.CustID = ip_CustID
		AND s.ActionStatus = 1;
    
	INSERT INTO CTS_DataCenter.CTSCustomerClassification(CTSCustID, CustID, SubscriberID, CategoryID, SportGroupID , Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
	SELECT 	ip_CTSCustID
		, 	ip_CustID
		, 	ip_SubscriberID
        , 	ip_CategoryID
        , 	s.SportGroupID
        , 	ip_Remark
        , 	lv_CurrentTime
        ,   ip_CreatedBy
        ,   lv_CurrentTime 
        ,   ip_CreatedBy
    FROM Temp_SportGroupID AS s
    WHERE s.ActionStatus = 0;
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(11, 'CTS_DC_CustClassification_Update', CONCAT('Update CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID, ';ip_CategoryID_', ip_CategoryID, ';ip_SportGroupIDList_', ip_SportGroupIDList, ';ip_Remark_', ip_Remark,')'), lv_CurrentTime, ip_CreatedBy);

END$$	

DELIMITER ;