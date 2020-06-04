DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationByCategory$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationByCategory(IN ip_CategoryIDList VARCHAR(1000))
BEGIN
	/*
		Created:	20200604@Casey.Huynh
		Task:		Return the auto tag customer list by ip_category
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/   
    
    CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(ip_CategoryIDList, ',', 'SMALLINT UNSIGNED');   
	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT 		ccl.CustID
				, ccl.SportGroupID
                , ccl.CategoryID
    FROM		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN	CTS_DataCenter.CustomerCategory AS cat
				ON ccl.CategoryID = cat.CategoryID
    INNER JOIN 	TempItemTable AS ctg	# the temp table return from sp CTS_DC_Sys_SplitStringToTempItemTable
	WHERE		cat.IsActive = 1
				AND ccl.CategoryID = ctg.Item;
    
END$$
DELIMITER ;
