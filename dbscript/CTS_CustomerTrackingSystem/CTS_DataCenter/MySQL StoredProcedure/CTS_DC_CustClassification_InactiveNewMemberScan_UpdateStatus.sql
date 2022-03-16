/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InactiveNewMemberScan_UpdateStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE  `CTS_DataCenter`.`CTS_DC_CustClassification_InactiveNewMemberScan_UpdateStatus`(
		IN ip_LastCustID 		BIGINT UNSIGNED
    ,	IN ip_LastScannedTime 	DATETIME
)
    SQL SECURITY INVOKER
sp:BEGIN
/*
		Created:	20220317@Irena.Vo
		Task:		Update Setting Parameters after Scanning for Inactive New Member [Redmine ID: #169960]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220317@Irena.Vo: Created [Redmine ID: #169960]
		Param's Explanation (filtered by):
		Example: 
			- CALL CTS_DataCenter.CTS_DC_CustClassification_InactiveNewMemberScan_UpdateStatus(100,'2022-02-02 00:00:00');
	*/    
        UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = ip_LastCustID 
        WHERE ParameterID = 80;
        
        UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = ip_LastScannedTime 
        WHERE ParameterID = 81;
END$$
DELIMITER ; 