DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(IN ip_String TEXT, IN ip_Seperator VARCHAR(10), IN ip_toDataType VARCHAR(100))
BEGIN
	/*
		Created:	20200604@Casey.Huynh
		Task:		Return Table Item with datatype = 
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
                

    	*/ 
        
        
	DROP TEMPORARY TABLE IF EXISTS TempItemTable;
    SET @schemaStr =  CONCAT('CREATE TEMPORARY TABLE TempItemTable(Item ',ip_toDataType,');');
    
    PREPARE schemaStr FROM @schemaStr;
    EXECUTE schemaStr;
    
	SET @insertStr = CONCAT("INSERT INTO TempItemTable (Item) VALUES ('", REPLACE(ip_String, ip_Seperator, "'),('"),"');");

	PREPARE insertStr FROM @insertStr;
	EXECUTE insertStr;
END$$
DELIMITER ;
