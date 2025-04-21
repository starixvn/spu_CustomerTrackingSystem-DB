/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustomerLatency_Queue_Complete`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustomerLatency_Queue_Complete`(
		IN 	ip_Customer		JSON
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
			CustID							BIGINT UNSIGNED PRIMARY KEY
		,	CustInfoRepUpdateTime			DATETIME(7)
		,	SiteRepUpdateTime				DATETIME(7)
		,	DepCustSuperRepUpdateTime		DATETIME(7)
		,	CustProductStatusRepUpdateTime	DATETIME(7)
	);

	INSERT IGNORE INTO Temp_CustID(CustID, CustomerRepUpdateTime, CustInfoRepUpdateTime, SiteRepUpdateTime, DepCustSuperRepUpdateTime, CustProductStatusRepUpdateTime)
	SELECT 	js.CustID
		,	js.CustInfoRepUpdateTime
        ,	js.SiteRepUpdateTime
        ,	js.DepCustSuperRepUpdateTime
        ,	js.CustProductStatusRepUpdateTime
    FROM JSON_TABLE(ip_Sporttype,
					 "$[*]" COLUMNS(
								CustID							INT	PATH "$.CustID"
							,	CustInfoRepUpdateTime			INT	PATH "$.CustInfoRepUpdateTime"
                            ,	SiteRepUpdateTime				INT	PATH "$.SiteRepUpdateTime"
                            ,	DepCustSuperRepUpdateTime		INT	PATH "$.DepCustSuperRepUpdateTime"
                            ,	CustProductStatusRepUpdateTime	INT	PATH "$.CustomerRepUpdateTime"
						)
				) AS js;
                
	INSERT INTO CTS_DataCenter.CTSCustomerLatencyQueue_Archive (CustID, LatencyType, InsertedTime)
	SELECT	clq.CustID
		,	clq.LatencyType
		,	clq.InsertedTime
        ,	clq.CustomerRepUpdateTime
        ,	tmp.CustInfoRepUpdateTime
        ,	tmp.SiteRepUpdateTime
        ,	tmp.DepCustSuperRepUpdateTime
        ,	tmp.CustProductStatusRepUpdateTime
	FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomerLatencyQueue AS clq ON clq.CustID = tmp.CustID;

	DELETE clq
	FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomerLatencyQueue AS clq ON clq.CustID = tmp.CustID;

END$$
DELIMITER ;