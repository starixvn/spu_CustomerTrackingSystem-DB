/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_History_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_History_Get`(
		IN ip_CustID 	BIGINT
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
                
		Param's Explanation:
        
        Example:
				CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_History_Get(@CustID:=43600693, @ip_SportID:=2);
*/ 

    SELECT	clh.ID
		,	clh.CustID
		,	clh.CTSCustID
		,	clh.SportID
		,	clh.CategoryID
        ,	cat.CategoryName
		,	clh.TurnoverRM
		,	clh.WinlossRM
		,	clh.BetCount
		,	clh.ActiveDays
		,	clh.TargetCC
		,	clh.LastModifiedDate 
		,	IFNULL(us.UserName, clh.LastModifiedBy) AS CreatedBy
    FROM	CTS_DataCenter.CTSCustomerClassification_BySport_History AS clh
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON clh.CategoryID = cat.CategoryID
        LEFT JOIN CTS_Admin.CTSUser AS us ON clh.LastModifiedBy = us.UserID
    WHERE	clh.CustID = ip_CustID AND clh.SportID = ip_SportID;
    
END$$
DELIMITER ;