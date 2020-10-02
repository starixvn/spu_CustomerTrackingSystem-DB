DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DC_CustInfo_CheckCustNotExistedByCustIds $$

CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_CustInfo_CheckCustNotExistedByCustIds`(IN ip_CustIDList VARCHAR(2000))
BEGIN
	/*
		Created:	20201002@Harvey.Nguyen
		Task :		Check customer if they are existed in CTSCustomer
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Long.Luu: Created [Redmine ID: 139701]
		
		Param's Explanation (filtered by):
        
        call CTS_DC_CustInfo_CheckCustNotExistedByCustIds("72,1261,1262,1264");
	*/
    
    DROP TABLE IF EXISTS TempCustomer;
    CREATE TEMPORARY TABLE TempCustomer(
			CustID 	INT PRIMARY KEY
	);
    
	SET @sql = CONCAT("INSERT INTO TempCustomer (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
	SELECT tcust.CustID
	FROM TempCustomer tcust
	LEFT JOIN CTS_DataCenter.CTSCustomer cust ON tcust.CustID = cust.CustID
		AND cust.CustSubID = 0
	WHERE cust.CustID IS NULL;
        
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    DROP TABLE TempCustomer;
    
END$$
DELIMITER ;
