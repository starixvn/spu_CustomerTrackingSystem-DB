USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertCategorizedProblemAccounts`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertCategorizedProblemAccounts`(IN ip_ProblemAccounts JSON)
BEGIN
	/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200715@Long.Luu [Redmine ID: #136460]: Created 
            - 20200908@Irena.Vo [Redmine ID: #141020]: Enhance Exclude VVIP Customers, Pin
		Param's Explanation (filtered by):
                
	*/   
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938; 
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT NOW();
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts 
    (	    CustID				BIGINT UNSIGNED
        , 	MainDBCategoryID	SMALLINT UNSIGNED
        , 	CategoryID			SMALLINT UNSIGNED
        , 	CTSCustID			BIGINT UNSIGNED DEFAULT NULL
        , 	SubscriberID		INT DEFAULT NULL
        ,	IsNew				BIT DEFAULT 0
		, 	PRIMARY KEY			PK_Temp_ProblemAccounts_CustID(CustID)  
        ,	INDEX				IX_Temp_ProblemAccounts_IsNew(IsNew)  
    );     
    
    INSERT INTO Temp_ProblemAccounts(CustID, MainDBCategoryID)
	SELECT 	temp.CustID
		, 	temp.MainDBCategoryID
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, MainDBCategoryID	SMALLINT UNSIGNED	PATH "$.CategoryId"	
		 )) AS temp;   
         
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;     
    SET SQL_SAFE_UPDATES = 0;
    
     -- Ignore VVIP, Pin Category before
    DELETE temp
    FROM Temp_ProblemAccounts AS temp
           INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID
	WHERE sc.CreatedFromFunction IN (11, 21);
    
    -- Remove Normal & General category before
    DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	WHERE cc.ParentID IN (1, 200);
   
	-- Remove invalid category
    DELETE temp
    FROM Temp_ProblemAccounts AS temp
    WHERE temp.MainDBCategoryID = 0;
   
   -- Update Category in CTS
    UPDATE Temp_ProblemAccounts
    SET CategoryID =   CASE 
							WHEN MainDBCategoryID = 27 THEN 51
                            WHEN MainDBCategoryID = 28 THEN 52
                            WHEN MainDBCategoryID = 29 THEN 53
                            WHEN MainDBCategoryID = 30 THEN 54
                            WHEN MainDBCategoryID = 31 THEN 55
                            WHEN MainDBCategoryID = 32 THEN 56
                            WHEN MainDBCategoryID = 36 THEN 57
                            WHEN MainDBCategoryID = 37 THEN 58
                            WHEN MainDBCategoryID = 38 THEN 59
                            WHEN MainDBCategoryID = 101 THEN 151
                            WHEN MainDBCategoryID = 102 THEN 152
                            WHEN MainDBCategoryID = 103 THEN 153
                            WHEN MainDBCategoryID = 104 THEN 154
                            WHEN MainDBCategoryID = 105 THEN 155
                            WHEN MainDBCategoryID = 106 THEN 156
                            WHEN MainDBCategoryID = 107 THEN 157
                            WHEN MainDBCategoryID = 108 THEN 158
                            WHEN MainDBCategoryID = 109 THEN 159
                            WHEN MainDBCategoryID = 255 THEN 160
						END;
    -- Get New PA 
	UPDATE Temp_ProblemAccounts AS temp
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID
	SET	temp.IsNew = 1
    WHERE cate.CustID IS NULL; 
    
    -- Update info ctscustid , subscriberid
    UPDATE Temp_ProblemAccounts AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cate ON temp.CustID = cate.CustID
	SET		temp.CTSCustID = cate.CTSCustID
		, 	temp.SubscriberID = cate.SubscriberID
	WHERE temp.IsNew = 1;
    
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
    (CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID,CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	temp.CategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM Temp_ProblemAccounts AS temp
    WHERE temp.IsNew = 1;            
    
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN Temp_ProblemAccounts AS temp ON	temp.CustID = cate.CustID
 	SET  	cate.CategoryID = temp.CategoryID 
		,	cate.SportGroupID = 0
		,	cate.LastModifiedDate = lv_CurrentDateTime
        , 	cate.LastModifiedBy = lv_CreatedBy
        , 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE temp.IsNew = 0;
     
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID,LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.CategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	0
		, 	0
		, 	0
		, 	0
		, 	CASE WHEN temp.IsNew = 0 THEN 2 ELSE 1 END
		, 	1
		, 	DATE(lv_CurrentDateTime)
	FROM 	Temp_ProblemAccounts AS temp;   
    
	SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$

DELIMITER ;