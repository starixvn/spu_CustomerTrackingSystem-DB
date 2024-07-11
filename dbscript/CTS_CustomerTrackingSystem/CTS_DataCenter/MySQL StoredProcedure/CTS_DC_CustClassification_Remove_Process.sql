/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Remove_Process`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove_Process`(
		IN	ip_InputFlowID			INT
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- CTS_DC_CustClassification_Remove_Process ();
*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_GetInfo (ip_InputFlowID,ip_CustInfo);
	
	
END$$
DELIMITER ;