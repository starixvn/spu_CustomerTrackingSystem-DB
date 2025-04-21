/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustomerLatency_Queue_Complete`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustomerLatency_Queue_Complete`(
		IN 	ip_CustIDs	LONGTEXT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250416@Thomas.Nguyen
		Task:	 	Clean up Customer from Latency Queue for Customer Latency Insert and move to Archive
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20241203@Thomas.Nguyen: 	Created [Redmine ID: #223443]

		Example:
			CALL CTS_DC_CustomerLatency_Queue_Complete ('28941539,30401421,31787544');
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID( 	  
		CustID		BIGINT UNSIGNED PRIMARY KEY
	);

    SET @sql = CONCAT("INSERT INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	INSERT INTO CTS_DataCenter.CTSCustomerLatencyQueue_Archive (CustID, LatencyType, InsertedTime)
	SELECT	clq.CustID
		,	clq.LatencyType
		,	clq.InsertedTime
	FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomerLatencyQueue AS clq ON clq.CustID = tmp.CustID;

	DELETE clq
	FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomerLatencyQueue AS clq ON clq.CustID = tmp.CustID;

END$$
DELIMITER ;