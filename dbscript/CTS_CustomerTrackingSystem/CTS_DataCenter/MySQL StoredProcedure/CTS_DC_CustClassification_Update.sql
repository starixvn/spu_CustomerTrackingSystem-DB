/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Update`(OUT op_ErrorMessage varchar(200),IN ip_CTSCustID bigint,IN ip_CustID bigint,IN ip_SubscriberID int,IN ip_CategoryID smallint,IN ip_SportGroupIDList varchar(50),IN ip_Remark varchar(300),IN ip_CreatedBy int)
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
            
		Param's Explanation:
	*/ 
    DECLARE vr_CurrentTime DATETIME DEFAULT CURRENT_TIME();
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
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS t 
        ON t.SportGroupID = s.SportGroupID AND t.CategoryID = ip_CategoryID
	SET s.ActionStatus = 1
    WHERE t.CTSCustID = ip_CTSCustID;
    
    DELETE t
    FROM CTS_DataCenter.CTSCustomerClassification AS t
		LEFT JOIN tempSportGroupID AS s 
        ON t.SportGroupID = s.SportGroupID
    WHERE t.CTSCustID = ip_CTSCustID
		AND t.CategoryID = ip_CategoryID
        AND s.SportGroupID IS NULL;
    
    UPDATE 	CTS_DataCenter.CTSCustomerClassification AS t
		INNER JOIN tempSportGroupID AS s ON t.SportGroupID = s.SportGroupID AND t.CategoryID = ip_CategoryID
    SET 	t.Remark = ip_Remark
        ,	t.LastModifiedBy = ip_CreatedBy
		,	t.LastModifiedDate = vr_CurrentTime
	WHERE t.CustID = ip_CustID
		AND s.ActionStatus = 1;
    
	INSERT INTO CTS_DataCenter.CTSCustomerClassification(CTSCustID, CustID, SubscriberID, CategoryID, SportGroupID
		, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
	SELECT 	ip_CTSCustID
		, 	ip_CustID
		, 	ip_SubscriberID
        , 	ip_CategoryID
        , 	s.SportGroupID
        , 	ip_Remark
        , 	vr_CurrentTime, ip_CreatedBy, vr_CurrentTime , ip_CreatedBy
    FROM tempSportGroupID AS s
    WHERE s.ActionStatus = 0;
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(11, 'CTS_DC_CustClassification_Update', CONCAT('Update CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID, ';ip_CategoryID_', ip_CategoryID, ';ip_SportGroupIDList_', ip_SportGroupIDList, ';ip_Remark_', ip_Remark,')'), vr_CurrentTime, ip_CreatedBy);

END$$	

DELIMITER ;