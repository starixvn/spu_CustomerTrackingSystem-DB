/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InactiveNewMemberScan_UpdateStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE  `CTS_DataCenter`.`CTS_DC_CustClassification_InactiveNewMemberScan_UpdateStatus`(
		IN ip_LastCreatedDate 	DATETIME
	,	IN ip_LastCTSCustID 	BIGINT UNSIGNED
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
			- CALL CTS_DataCenter.CTS_DC_CustClassification_InactiveNewMemberScan_UpdateStatus('2020-01-01 00:00:00',1200);
	*/    
        UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = ip_LastCreatedDate
        WHERE ParameterID = 80;
        
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = ip_LastCTSCustID
        WHERE ParameterID = 81;
        
        UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = CURRENT_TIMESTAMP() 
        WHERE ParameterID = 82;
END$$
DELIMITER ; 