/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_MissingCustomer_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_MissingCustomer_Complete`(
	IN ip_LastScannedID		BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20241213@Jonas.Huynh
		Task:		Missing Customer [Redmine ID: 214157]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20241213@Jonas.Huynh: Missing Customer [Redmine ID: 214157]
            
		Param's Explanation (filtered by):
            
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Complete();

	*/
    DECLARE CONST_MISSING_NEWCUSTOMER				TINYINT DEFAULT 2;
    DECLARE CONST_MISSING_REACTIVATEDCUSTOMER		TINYINT DEFAULT 50;
    
    IF (ip_LastScannedID IS NOT NULL AND ip_LastScannedID > 0) THEN
		UPDATE CTS_DataCenter.JobMonitoring_IncorrectData AS a
			INNER JOIN CTS_DataCenter.StaticList AS s ON s.ItemID = a.IssueTypeID 
				AND s.ListID = 20 
				AND s.ItemID IN (CONST_MISSING_NEWCUSTOMER, CONST_MISSING_REACTIVATEDCUSTOMER)
		SET IsResolved = 1
		WHERE ID <= ip_LastScannedID 
			AND IsResolved = 0
		ORDER BY ID ASC;
	 
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = ip_LastScannedID
		WHERE ParameterID = 185;
	END IF;
END$$
DELIMITER ;