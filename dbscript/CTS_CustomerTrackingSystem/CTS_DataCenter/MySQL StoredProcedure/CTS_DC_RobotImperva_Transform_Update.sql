/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_RobotImperva_Transform_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_RobotImperva_Transform_Update`(	
		IN ip_RobotInfo		TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20230315@Victoria.le
		Task:	 	Robot Imperva - Update IsScan
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20230315@Victoria.le:		Initial Writing [Redmine ID: #184773]

		Example:
			CALL CTS_DC_RobotImperva_Transform_Update (@ip_RobotInfo := '[{LogID:1},{LogID:2}]');
	
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotImperva;    
	CREATE TEMPORARY TABLE Temp_RobotImperva(	  
			LogID		BIGINT	PRIMARY KEY
	);

	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_RobotImperva (LogID) VALUES ('", REPLACE(ip_RobotInfo, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
    UPDATE CTS_DataCenter.RobotImperva AS r
		INNER JOIN Temp_RobotImperva AS tmp ON tmp.LogID = r.LogID
	SET r.IsScan = 1
    WHERE r.IsScan = 0;
    
END$$
DELIMITER ;