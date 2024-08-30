/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_History_Clean`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_History_Clean`(
    	IN	ip_Batchsize					INT
    ,	IN	ip_MinHistoryID					BIGINT
    ,	OUT	op_MaxHistoryID					BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240826@Victoria.Le
		Task:		Clean history - BySport if over 30 days (keep max) + latest 30 days (keep > min(ID))
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_History_Clean(1000,9999,op_MaxHistoryID);
			
		Revisions: 
			- 20240826@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/

	DECLARE lv_FromID						BIGINT DEFAULT 0;
	DECLARE lv_ToID							BIGINT DEFAULT 0;
	
	WITH CTE AS
	(
		SELECT hadhoc.ID
		FROM CTS_DataCenter.AdhocVic_History_Bysport_DELETE AS hadhoc 
		WHERE hadhoc.ID >= ip_MinHistoryID
		ORDER BY hadhoc.ID
		LIMIT ip_Batchsize
	)
	SELECT MIN(c.ID), MAX(c.ID)
	INTO lv_FromID, lv_ToID
	FROM CTE AS c;


	DELETE hmain
	FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS hmain
		INNER JOIN CTS_DataCenter.AdhocVic_History_Bysport_DELETE AS hadhoc ON hadhoc.ID = hmain.ID
	WHERE hadhoc.ID BETWEEN lv_FromID AND lv_ToID;
	
	SELECT hadhoc.ID
	INTO op_MaxHistoryID
	FROM AdhocVic_History_Bysport_DELETE AS hadhoc 
	WHERE hadhoc.ID > lv_ToID
	ORDER BY hadhoc.ID
	LIMIT 1;
	
	IF op_MaxHistoryID IS NULL THEN
		SET op_MaxHistoryID = ip_MinHistoryID;
	END IF;
	

END$$

DELIMITER ;