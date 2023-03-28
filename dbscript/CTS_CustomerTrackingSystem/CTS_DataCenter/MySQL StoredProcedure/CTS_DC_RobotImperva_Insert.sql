/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotImperva_Insert`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotImperva_Insert`(
		IN 	ip_RobotInfo 		JSON
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20230315@Victoria.le
		Task:	 	Robot Imperva - Insert data after getting from TW
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20230315@Victoria.le:		Initial Writing [Redmine ID: #184773]

		Example:
			CALL CTS_DC_RobotImperva_Insert (@ip_RobotInfo := '[{"LogID":579,"CustID":3451523,"Platform":1,"CreateTime":"2022-12-29T04:13:50.290"},{"LogID":617,"CustID":3448918,"Platform":1,"CreateTime":"2022-12-29T04:14:13.030"},{"LogID":752,"CustID":66984,"Platform":1,"CreateTime":"2022-12-09T06:09:16.930"},{"LogID":780,"CustID":3818259,"Platform":1,"CreateTime":"2022-12-09T06:09:20.560"},{"LogID":806,"CustID":2713661,"Platform":1,"CreateTime":"2022-12-09T06:09:24.190"},{"LogID":831,"CustID":3833463,"Platform":1,"CreateTime":"2022-12-09T06:09:26.997"},{"LogID":868,"CustID":3758407,"Platform":1,"CreateTime":"2022-12-09T06:09:33.633"},{"LogID":957,"CustID":3447225,"Platform":1,"CreateTime":"2022-12-09T06:09:49.200"}]');
	
	*/
    INSERT INTO CTS_DataCenter.RobotImperva 
    (
			LogID			
		,	CustID			
		,	Platform		
		,	CreateTime	
    )
    SELECT 	js.LogID			
		,	js.CustID			
		,	js.Platform		
		,	js.CreateTime	
	FROM JSON_TABLE(ip_RobotInfo,
					"$[*]" COLUMNS( 	LogID 			BIGINT		PATH "$.LogID"                
									,	CustID			INT 		PATH "$.CustID"
									,	Platform		SMALLINT	PATH "$.Platform"
									,	CreateTime		DATETIME(3)	PATH "$.CreateTime"
					)) AS js
	ON DUPLICATE KEY UPDATE LastModifiedDate = js.CreateTime;
END$$
DELIMITER ;