/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_ProblemCaseMonitor`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_ProblemCaseMonitor`(
		IN ip_FromDate	DATETIME
	,	IN ip_ToDate	DATETIME
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20210612@Casey.Huynh
		Task:  Return Customer Fraud Type [RedmineID: #156464]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20210612@Casey.Huynh: Created [RedmineID: #156464]
		Param's Explanation (filtered by):
            - ip_CategoryIDList: ex: '1,2,3' 
		Example: CTS_DC_RPT_ProblemAccountMonitor('2021-06-14');
	*/ 
    DECLARE lv_StaticListID INT;
    DECLARE lv_Robot INT DEFAULT 1;
    DECLARE lv_GroupBetting INT DEFAULT 2;
    DECLARE lv_SuspiciousAssociation INT DEFAULT 3;
    DECLARE lv_ProPunter INT  DEFAULT 4;

    SELECT	UserName, SubscriberName
				, (CASE WHEN pam.ProblemType = lv_Robot THEN 1 ELSE 0 END) 'Robot'
				, (CASE WHEN pam.ProblemType = lv_GroupBetting THEN 1 ELSE 0 END) 'GroupBetting'
				, (CASE WHEN pam.ProblemType = lv_SuspiciousAssociation THEN 1 ELSE 0 END) 'SuspiciousAssociation'
				, (CASE WHEN pam.ProblemType = lv_ProPunter THEN 1 ELSE 0 END) 'ProPunter'
		FROM	CTS_DataCenter.ProblemAccountMonitor AS pam
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON pam.CustID = cus.CustID AND pam.CustSubID = cus.CustSubID
			INNER JOIN CTS_Admin.Subscriber AS sub ON cus.SubscriberID = sub.SubscriberID
		WHERE	pam.CreatedDate = ip_Date;

	SELECT 	UserName
		,	SubscriberName
		,	MAX(Robot) AS 'Robot'
        ,	MAX(GroupBetting) AS 'GroupBetting'
        ,	MAX(SuspiciousAssociation) AS 'SuspiciousAssociation'
        ,	MAX(ProPunter) AS 'ProPunter'
    FROM (
		SELECT	UserName, SubscriberName
				, (CASE WHEN pam.ProblemType = lv_Robot THEN 1 ELSE 0 END) 'Robot'
				, (CASE WHEN pam.ProblemType = lv_GroupBetting THEN 1 ELSE 0 END) 'GroupBetting'
				, (CASE WHEN pam.ProblemType = lv_SuspiciousAssociation THEN 1 ELSE 0 END) 'SuspiciousAssociation'
				, (CASE WHEN pam.ProblemType = lv_ProPunter THEN 1 ELSE 0 END) 'ProPunter'
		FROM	CTS_DataCenter.ProblemAccountMonitor AS pam
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON pam.CustID = cus.CustID AND pam.CustSubID = cus.CustSubID
			INNER JOIN CTS_Admin.Subscriber AS sub ON cus.SubscriberID = sub.SubscriberID
		WHERE	pam.CreatedDate = ip_Date) AS tmp
   GROUP BY tmp.UserName, tmp.SubscriberName
   ORDER BY UserName;
END$$

DELIMITER ;