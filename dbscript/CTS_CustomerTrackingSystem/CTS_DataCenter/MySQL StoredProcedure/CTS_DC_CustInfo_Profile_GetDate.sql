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

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Profile_GetDate(200);
	*/
    DECLARE	CONST_GROUP_NORMAL 		INT DEFAULT 200;
    
	DECLARE lv_NextCategoryScan		DATE;
    DECLARE lv_LastTicket 			DATETIME;
    DECLARE lv_LastLogin 			DATETIME;
    DECLARE lv_Created				DATETIME;
	
    SELECT MIN(DATE_ADD(clss.LastScannedDate, INTERVAL cate.ScanIntervalInSecond SECOND))
    INTO lv_NextCategoryScan
	FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID =  clss.CategoryID AND  cate.ScanIntervalInSecond > 0
	WHERE clss.CTSCustID = ip_CTSCustID
		AND clss.SportGroupID = CONST_GROUP_NORMAL;
    
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
    
    SELECT 	lv_NextCategoryScan AS NextCategoryScan
		,	lv_LastTicket		AS LastTicket
		,	lv_LastLogin 		AS LastLogin
		,	lv_Created 			AS Created;
END$$
DELIMITER ;