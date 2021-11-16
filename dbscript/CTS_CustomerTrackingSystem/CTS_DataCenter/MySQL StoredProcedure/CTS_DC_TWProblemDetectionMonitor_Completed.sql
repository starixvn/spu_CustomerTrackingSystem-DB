/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_Scan_Completed`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_Scan_Completed`(IN ip_LastCustID INT UNSIGNED)
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
    
	UPDATE CTS_DataCenter.SystemParameter AS s 
	SET s.ParameterValue = ip_LastCustID
	WHERE s.ParameterID = 63;  

END$$
DELIMITER ;

