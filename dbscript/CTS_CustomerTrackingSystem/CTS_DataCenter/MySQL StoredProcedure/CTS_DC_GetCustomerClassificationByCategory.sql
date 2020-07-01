DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationByCategory$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationByCategory(IN ip_CategoryIDList VARCHAR(1000), IN ip_CustSport JSON)
BEGIN
	/*
		Created:	[20200612@Casey.Huynh][135324]
		Task:		Return the auto tag customer list by ip_category
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			[20200701@Casey.Huynh]135324]: Chagne Flow and Store more Info
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/     
    
    DROP TEMPORARY TABLE IF EXISTS Temp_inputCategory;
    CREATE TEMPORARY TABLE Temp_inputCategory(
		CategoryID	SMALLINT UNSIGNED
    );
    
    #===GET Category List    
    CALL CTS_DataCenter.CTS_DC_Sys_SplitStringToTempItemTable(ip_CategoryIDList, ',', 'SMALLINT UNSIGNED');   # Return TempItemTable table within Item Column	
    INSERT INTO Temp_inputCategory (CategoryID)
    SELECT 	Item
    FROM 	TempItemTable;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_inputCustSport;
	CREATE TEMPORARY TABLE Temp_inputCustSport(
		CustID			BIGINT UNSIGNED
		, SportGroupID	SMALLINT UNSIGNED
	);
 
	INSERT INTO Temp_inputCustSport(CustID, SportGroupID)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) as tmpTable;       
    

    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT		tmpCusCat.CustID
				, tmpCusCat.SportGroupID AS SportGroupID
                , tmpCusCat.CategoryID
	FROM	(    
				SELECT 		cus.CustID AS CustID
							, cus.SportGroupID AS SportGroupID  
							, ccl.SportGroupID AS CurrentSportGroupID
							, ctg.CategoryID AS CategoryID
				FROM 	 	Temp_inputCustSport AS cus
				LEFT JOIN	CTS_DataCenter.CTSCustomerClassification AS ccl
							ON cus.CustID = ccl.CustID
								AND cus.SportGroupID = ccl.SportGroupID
				LEFT JOIN	Temp_inputCategory AS ctg
							ON ccl.CategoryID = ctg.CategoryID
			) AS tmpCusCat
	WHERE	tmpCusCat.CurrentSportGroupID IS NULL 
			OR tmpCusCat.CategoryID IS NOT NULL;

    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
