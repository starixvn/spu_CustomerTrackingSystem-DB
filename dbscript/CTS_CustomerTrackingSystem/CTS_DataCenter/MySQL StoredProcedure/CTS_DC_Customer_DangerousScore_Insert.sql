/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Customer_DangerousScore_Insert`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Customer_DangerousScore_Insert`(
		IN 	ip_CustInfo 		JSON
    ,	IN  ip_IsDeposit		TINYINT(1)
	
	,	OUT op_ErrorMessage 	VARCHAR(200)
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20230515@Victoria.le
		Task:	 	Customer DangerousScore - Insert data after getting from AI
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20230515@Victoria.le:		Initial Writing [Redmine ID: #186191]

		Example:
			CALL CTS_DC_Customer_DangerousScore_Insert ('[{"CustID":3451523,"DangerousScore":0.0074},{"CustID":3448918,"DangerousScore":0.0386},{"CustID":66984,"DangerousScore":0.5426},{"CustID":3818259,"DangerousScore":0.0022},{"CustID":2713661,"DangerousScore":0.2338},{"CustID":3833463,"DangerousScore":0.0058}]');

	*/
	DECLARE lv_CreatedDate DATETIME(3);
	
	SET lv_CreatedDate = CURRENT_TIMESTAMP();
	
    INSERT INTO CTS_DataCenter.Customer_DangerousScore 
    (
			CustID
		,	IsDeposit
		,	DangerousScore
		,	CreatedDate		
		,	LastModifiedDate	
    )
    SELECT 	js.CustID		
		,	ip_IsDeposit	
		,	js.DangerousScore		
		,	lv_CreatedDate
		,	lv_CreatedDate
	FROM JSON_TABLE(ip_CustInfo,
					"$[*]" COLUMNS( 	CustID				INT 			PATH "$.CustID"
									,	DangerousScore		DECIMAL(6,4)	PATH "$.DangerousScore"
					)) AS js
	ON DUPLICATE KEY UPDATE DangerousScore 		= js.DangerousScore
						,	LastModifiedDate 	= lv_CreatedDate;
	
END$$
DELIMITER ;