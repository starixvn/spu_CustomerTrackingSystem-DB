USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_AssociatedAccountReport_Get`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_AssociatedAccountReport_Get`(IN ip_CTSCustIDList VARCHAR(4000))
BEGIN
	/*
		Created:	20201028@Lex.Khuat
		Task :		Implement general category list for associated account report
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201028@Lex.Khuat [Redmine ID: #131499]: Created
            
		Param's Explanation:
			Sample: call CTS_DataCenter.CTS_DC_AssociatedAccountReport_Get('1,2,3,4,5,6,7,8,9,10');
            - ip_CTSCustIDList: list of ctscustid to get
	*/ 

	#============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    #============================================
    
    CREATE TEMPORARY TABLE Temp_Customer (
			CTSCustID		BIGINT UNSIGNED
    );

    #========= FILTER LIST =========
    IF IFNULL(ip_CTSCustIDList, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO Temp_Customer (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
    END IF;
    
	#========= GET DATA =========
    SELECT	cc.CTSCustID
		,	LEFT(GROUP_CONCAT(DISTINCT cat.CategoryName ORDER BY cat.CategoryID ASC SEPARATOR ', '), 255) AS CategoryList
    FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat
			ON cc.CategoryID = cat.CategoryID
		INNER JOIN Temp_Customer AS cust
			ON cc.CTSCustID = cust.CTSCustID
	WHERE cat.ParentID in (50, 200)
		AND cc.CTSCustID IS NOT NULL
    GROUP BY cc.CTSCustID;
    
END$$

DELIMITER ;

