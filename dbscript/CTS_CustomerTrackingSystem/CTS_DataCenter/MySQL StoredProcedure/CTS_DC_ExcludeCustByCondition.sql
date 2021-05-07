/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ExcludeCustByCondition`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ExcludeCustByCondition`(IN ip_TableName VARCHAR(200))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210507@Casey.Huynh
		Task:		Exclude CustID from ip_CustIDList when Cust's SiteID exists in ip_StaticListID.ItemIDs [Redmine ID: 154694]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210507@Casey.Huynh: Created [Redmine ID: 154694]
		Param's Explanation (filtered by):
			ip_StaticListID: ListID(siteID) in table StaticList
            ip_CustIDList
        CALL CTS_DataCenter.CTS_DC_FilterCustListByStaticSite(11);
	*/
    
    SET @insertStr =CONCAT(	"DELETE tbl 
							FROM ",ip_TableName," as tbl 
							INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tbl.CustID
										AND cus.SiteID IN (192,283,463)");
    
	PREPARE insertStr FROM @insertStr;
	EXECUTE insertStr;
END$$
DELIMITER ;