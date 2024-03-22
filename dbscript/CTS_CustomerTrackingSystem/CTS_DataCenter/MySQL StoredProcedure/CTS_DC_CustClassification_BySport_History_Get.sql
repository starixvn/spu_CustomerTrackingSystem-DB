/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_History_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_History_Get`(
		IN ip_CTSCustID 	BIGINT
	,	IN ip_SportID	INT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20220908@Casey.Huynh
		Task:		Get Cust Classification Details by sport
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20220908@Casey.Huynh: Created [Redmine ID: #176992]
                - 20240320@Thomas.Nguyen: Return more Remark, SourceTypeName, SourceTypeID [Redmine ID: #201360]

		Param's Explanation:
        
        Example:
        SELECT * FROM CTSCustomerClassification_BySport_History;
				CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_History_Get(@CTSCustID:=572272, @ip_SportID:=2);
*/ 

    SELECT	clh.ID
		,	clh.CustID
		,	clh.CTSCustID
		,	clh.SportID
		,	clh.CategoryID
        ,	(CASE WHEN clh.CategoryID IS NULL THEN '-' ELSE cat.CategoryName END) AS CategoryName
		,	clh.TurnoverRM
		,	clh.WinlossRM
		,	clh.BetCount
		,	clh.ActiveDays
		,	clh.TargetCC
		,	clh.LastModifiedDate 
		,	IFNULL(us.UserName, clh.LastModifiedBy) AS CreatedBy
		,	s.ItemNameDisplay AS SourceTypeName
		,	clh.Remark
		,	s.ItemID AS SourceTypeID
    FROM	CTS_DataCenter.CTSCustomerClassification_BySport_History AS clh
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON clh.CategoryID = cat.CategoryID
        LEFT JOIN CTS_Admin.CTSUser AS us ON clh.LastModifiedBy = us.UserID
		LEFT JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 4 AND clh.SourceTypeID = s.ItemID
    WHERE	clh.CTSCustID = ip_CTSCustID AND clh.SportID = ip_SportID
    ORDER BY clh.LastModifiedDate DESC;
    
END$$
DELIMITER ;