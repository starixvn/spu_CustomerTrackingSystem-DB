/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Common_GetCustomerGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Common_GetCustomerGroup`(IN ip_CustomerTransDateList json)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
            
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
	)) AS tmpTable;
    
	SELECT 	c.CustID
		,	c.TransID
		,	g.GroupID
    FROM tmpCustomerTransDate AS c
		LEFT JOIN CTS_DataCenter.SmartGroupHistory AS g ON c.CustID = g.CustID AND c.TransDate = g.CreatedDate;
    
END$$	
DELIMITER ;