/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Profile_GetDate`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Profile_GetDate`(
		IN ip_CTSCustID BIGINT UNSIGNED 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211214@Aries.Nguyen	
		Task :		Enrich the information on customer profile
		DB:			CTS_DataCenter
		
		Revisions:
			- 20211214@Aries.Nguyen: Created [Redmine ID: #165105]
- 20220407@Irena.Vo: Get additional date for New Member(no bet in 30 last days), PA, Robot [Redmine ID: #170468]

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Profile_GetDate(200);
	*/
    DECLARE	CONST_GROUP_NORMAL 				INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM				INT DEFAULT 0;
    
    DECLARE	CONST_CATEGORYGROUP_PROBATION 	INT DEFAULT 206;
    DECLARE	CONST_CATEGORYGROUP_NEWMEMBER 	INT DEFAULT 201;
    DECLARE	CONST_CATEGORYGROUP_ROBOT 		INT DEFAULT 61;
    
	DECLARE lv_NextCategoryScan		DATE;
    DECLARE lv_LastTicket 			DATETIME;
    DECLARE lv_LastLogin 			DATETIME;
    DECLARE lv_Created				DATETIME;
	
	SELECT 	LastLoginTime
		, 	CreatedDate 
	INTO 	lv_LastLogin
		, 	lv_Created
	FROM CTS_DataCenter.CTSCustomer 
	WHERE CTSCustID = ip_CTSCustID;
    
    SELECT LastTicketDate 
    INTO lv_LastTicket
	FROM CTS_Archive.CTSCustomerAssociationStatus 
	WHERE CTSCustID = ip_CTSCustID;
    
    /* PA Category (not robot) */
    SELECT DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
    INTO lv_NextCategoryScan
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID =  clss.CategoryID
    WHERE clss.CTSCustID = ip_CTSCustID
			AND clss.SportGroupID = CONST_GROUP_PROBLEM AND cate.CategoryGroup <> CONST_CATEGORYGROUP_ROBOT
    LIMIT 1;
    
    /* Normal Category */
    IF (lv_NextCategoryScan IS NULL) THEN
		 SELECT CASE WHEN cate.CategoryGroup = CONST_CATEGORYGROUP_NEWMEMBER AND lv_LastTicket <= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY) THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
					 WHEN cate.CategoryGroup = CONST_CATEGORYGROUP_PROBATION AND clss.CreatedDate < DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY) THEN DATE(CURRENT_DATE())
					 WHEN cate.CategoryGroup = CONST_CATEGORYGROUP_PROBATION AND clss.CreatedDate >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY) THEN DATE(DATE_ADD(clss.CreatedDate, INTERVAL 3 DAY))
					 WHEN cate.ScanIntervalInSecond > 0 THEN DATE_ADD(clss.LastScannedDate, INTERVAL cate.ScanIntervalInSecond SECOND)
				 END 
		INTO lv_NextCategoryScan
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID =  clss.CategoryID
		WHERE clss.CTSCustID = ip_CTSCustID
			AND clss.SportGroupID = CONST_GROUP_NORMAL;
    END IF;
    
    SELECT 	lv_NextCategoryScan AS NextCategoryScan
		,	lv_LastTicket		AS LastTicket
		,	lv_LastLogin 		AS LastLogin
		,	lv_Created 			AS Created;
END$$
DELIMITER ;