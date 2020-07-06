DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCustomerGroup`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCustomerGroup`(
		IN ip_CustomerTransDateList 	JSON
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS tmpCustomerTransDate;
    CREATE TEMPORARY TABLE tmpCustomerTransDate (
			CustID 			INT
		,	TransID 		BIGINT
        ,	TransDate		DATE
    );
    
    ALTER TABLE tmpCustomerTransDate ADD INDEX CIX_tmpCustomerTransDate_CustIDTransDate (CustID, TransDate);
    
    INSERT INTO tmpCustomerTransDate(CustID, TransID, TransDate)
    SELECT tmpTable.CustID, tmpTable.TransID, tmpTable.TransDate
	FROM JSON_TABLE(ip_CustomerTransDateList,
		 "$[*]" COLUMNS(
		  CustID 		INT 			PATH "$.CustID"         
		, TransID		BIGINT			PATH "$.TransID"       
        , TransDate		DATE			PATH "$.TransDate"
	)) as tmpTable;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	SELECT 	c.CustID
		,	c.TransID
		,	g.GroupID
    FROM tmpCustomerTransDate AS c
		LEFT JOIN CTS_DataCenter.SmartGroupHistory AS g ON c.CustID = g.CustID AND c.TransDate = g.CreatedDate;   
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$	
DELIMITER ;