/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Device_Insert`(
    IN ip_TransIDs	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231124@Jonathan.Doan
	    Task : Identity Device
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Device_Insert('1,2,3');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;    
	CREATE TEMPORARY TABLE Temp_InputTrans(
		TransID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SELECT 	TransID
		,	-1 AS FPDeviceID
    FROM Temp_InputTrans;
END$$

DELIMITER ;
