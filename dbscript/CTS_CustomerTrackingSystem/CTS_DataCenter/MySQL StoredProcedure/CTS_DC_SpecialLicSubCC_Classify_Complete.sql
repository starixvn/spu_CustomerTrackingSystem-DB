/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_SpecialLicSubCC_Classify_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialLicSubCC_Classify_Complete`(
	IN ip_CustID TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250514@Casey.Huynh
		Task:	 	SpecialLicSubCC Scan Get
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250514@Casey.Huynh: 	Created [Redmine ID: #226847]

		Param's Explanation (filtered by): 

		Example:
			CALL CTS_DC_SpecialLicSubCC_Classify_Complete(@ip_CustID:='16647323,16683861');
	*/
    DECLARE CONST_PROCESSSTATUS_INPROGRESS	TINYINT DEFAULT 1;
    DECLARE CONST_PROCESSSTATUS_COMPLETE	TINYINT DEFAULT 2;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE Temp_CustID(
		CustID	INT PRIMARY KEY
    );
   
    SET @sql = CONCAT("INSERT INTO Temp_CustID(CustID) VALUES ('", REPLACE(ip_CustID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;   
	
    UPDATE CTS_DataCenter.Customer_SpecialLicSubCC AS cus
		INNER JOIN Temp_CustID AS tmp ON cus.CustID = tmp.CustID
	SET cus.ProcessStatus = CONST_PROCESSSTATUS_COMPLETE
    WHERE cus.ProcessStatus = 1;

END$$
DELIMITER ;
