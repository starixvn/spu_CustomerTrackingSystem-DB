/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustomerLatency_Queue_Insert`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustomerLatency_Queue_Insert`(
		IN 	ip_CustIDs 		LONGTEXT
	,	IN 	ip_LatencyType 	SMALLINT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250416@Thomas.Nguyen
		Task:	 	Insert Customer into Latency Queue for Customer Latency Insert
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250416@Thomas.Nguyen: 	Created [Redmine ID: #223443]

		Example:
			CALL CTS_DC_CustomerLatency_Queue_Insert ('28941539,30401421,31787544', 2);
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID( 	  
		CustID		BIGINT UNSIGNED PRIMARY KEY
	);

    SET @sql = CONCAT("INSERT INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerLatencyQueue (CustID, LatencyType)
	SELECT	tmp.CustID
		,	ip_LatencyType
	FROM Temp_CustID AS tmp;

END$$
DELIMITER ;