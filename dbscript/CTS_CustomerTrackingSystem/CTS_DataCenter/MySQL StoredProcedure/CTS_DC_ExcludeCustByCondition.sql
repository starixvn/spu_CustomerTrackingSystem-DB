/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_ExcludeCustByCondition`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ExcludeCustByCondition`(IN ip_ConditionType TINYINT, IN ip_TableName VARCHAR(200))
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
            - ip_ConditionType: 1: Remove CustID By SiteID
            - ip_TableName: the table name include CustID column
        CALL CTS_DataCenter.CTS_DC_ExcludeCustByCondition(1,'table_name');
	*/
    
    #--Exclude CustID by SiteID from table 'ip_TableName'
    
    IF (ip_ConditionType = 1)
    THEN		
		SET @insertStr =CONCAT(	"DELETE tbl 
								FROM ",ip_TableName," as tbl 
									INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tbl.CustID
									INNER JOIN CTS_DataCenter.StaticList AS stl ON stl.ItemID = cus.SiteID
											AND stl.ListID = 11" );
    END IF;
    
	PREPARE insertStr FROM @insertStr;
	EXECUTE insertStr;
END$$
DELIMITER ;