/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustomerLatency_Queue_Insert`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustomerLatency_Queue_Insert`(
		IN 	ip_Customer		JSON
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
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerLatencyQueue(CustID, CustomerRepUpdateTime, LatencyType)
    SELECT  js.CustID
		,	js.CustomerRepUpdateTime
		,	ip_LatencyType	
	FROM JSON_TABLE(ip_Sporttype,
					 "$[*]" COLUMNS(
								CustID					INT	PATH "$.CustID"
							,	CustomerRepUpdateTime	INT	PATH "$.CustomerRepUpdateTime"
						)
				) AS js;  
    

END$$
DELIMITER ;