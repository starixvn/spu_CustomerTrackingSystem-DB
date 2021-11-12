/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_Scan`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_Scan`()
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Return Cust list to scan
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: Created [Redmine ID: 164148]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_TWProblemDetectionMonitor_Scan();
	*/
    
	DELETE tpd
    FROM CTS_DataCenter.TWProblemDetectionMonitor AS tpd
		INNER JOIN CTS_Archive.CTSCustomerAssociationStatus AS cas ON tpd.CustID = cas.CustID
    WHERE DATEDIFF(CURRENT_DATE(), GREATEST(tpd.CreatedDate, cas.LastTicketDate)) >= 60;
    
    SELECT 	tpd.CustID
		,	tpd.UserName
		,	tpd.RoleID
		,	tpd.ReasonID
		,	tpd.PreventActionID
		,	tpd.Comment
		,	tpd.VoidTime
		,	tpd.LimitAcount
		,	tpd.UserID
		,	tpd.IP
        ,	(CASE WHEN cc.ParentID = 200 AND GROUP_CONCAT(cc.CategoryGroup) IN (201,202,205) THEN 1 ELSE 0 END) AS IsMonitorCategoryGroup 
        
    FROM CTS_DataCenter.TWProblemDetectionMonitor AS tpd
        INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON tpd.CustID = ccl.CustID 
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS ctc ON ccl.CategoryID = ctc.CategoryID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON ccl.CategoryID = cc.CategoryID
	WHERE tpd.CreatedDate < CURRENT_DATE()
	GROUP BY cc.ParentID, tpd.CustID, tpd.UserName, tpd.CustID, tpd.UserName, tpd.RoleID, tpd.ReasonID, tpd.PreventActionID, tpd.Comment, tpd.VoidTime, tpd.LimitAcount, tpd.UserID, tpd.IP;

END$$
DELIMITER ;

