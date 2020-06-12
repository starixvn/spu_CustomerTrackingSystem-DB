DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationByCategory$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationByCategory(IN ip_CategoryIDList VARCHAR(1000), ip_CustIDList TEXT)
BEGIN
	/*
		Created:	[20200612@Casey.Huynh][135324]
		Task:		Return the auto tag customer list by ip_category
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/   
    DROP TEMPORARY TABLE IF EXISTS Temp_CategoryList;
    CREATE TEMPORARY TABLE Temp_CategoryList(
		CategoryID	SMALLINT UNSIGNED
    );
    
    #===GET Category List    
    CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(ip_CategoryIDList, ',', 'SMALLINT UNSIGNED');   # Return TempItemTable table within Item Column	
    INSERT INTO Temp_CategoryList (CategoryID)
    SELECT 	Item
    FROM 	TempItemTable;
    
    #===GET Category List    
    CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(ip_CustIDList, ',', 'BIGINT UNSIGNED');   # Return TempItemTable table within Item Column	
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT 		ccl.CustID
				, ccl.SportGroupID
                , ccl.CategoryID
    FROM		CTS_DataCenter.CTSCustomerClassification AS ccl
	INNER JOIN	Temp_CategoryList AS ctg
				ON ccl.CategoryID = ctg.CategoryID
    INNER JOIN 	TempItemTable AS cus	# the temp table return from sp CTS_DC_Sys_SplitStringToTempItemTable
	WHERE		ccl.CustID = cus.Item;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
