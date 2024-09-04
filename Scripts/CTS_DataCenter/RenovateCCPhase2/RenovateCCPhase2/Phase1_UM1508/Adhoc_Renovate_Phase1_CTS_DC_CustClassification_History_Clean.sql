/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History_Clean`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History_Clean`(
    	IN	ip_Batchsize					INT
    ,	IN	ip_MinHistoryID					BIGINT
    ,	OUT	op_MaxHistoryID					BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240819@Victoria.Le
		Task:		Clean history if over 30 days
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_History_Clean(1000,9999,op_MaxHistoryID);
			
		Revisions: 
			- 20240819@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/

	DECLARE lv_FromID						BIGINT DEFAULT 0;
	DECLARE lv_ToID							BIGINT DEFAULT 0;
	
	WITH CTE AS
	(
		SELECT hadhoc.ID
		FROM CTS_Adhoc.Adhoc_CustIDID AS hadhoc 
		WHERE hadhoc.ID >= ip_MinHistoryID
		ORDER BY hadhoc.ID
		LIMIT ip_Batchsize
	)
	SELECT MIN(c.ID), MAX(c.ID)
	INTO lv_FromID, lv_ToID
	FROM CTE AS c;


	DELETE hmain
	FROM CTS_DataCenter.CTSCustomerClassification_History AS hmain
		INNER JOIN CTS_Adhoc.Adhoc_CustIDID AS hadhoc ON hadhoc.ID = hmain.ID
	WHERE hadhoc.ID BETWEEN lv_FromID AND lv_ToID;
	
	SELECT hadhoc.ID
	INTO op_MaxHistoryID
	FROM CTS_Adhoc.Adhoc_CustIDID AS hadhoc 
	WHERE hadhoc.ID > lv_ToID
	ORDER BY hadhoc.ID
	LIMIT 1;
	
	IF op_MaxHistoryID IS NULL THEN
		SET op_MaxHistoryID = ip_MinHistoryID;
	END IF;
	

END$$

DELIMITER ;