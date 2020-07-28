DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCategorizedProblemAccounts$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_InsertCategorizedProblemAccounts(IN ip_ProblemAccounts JSON)
BEGIN
	/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200715@Long.Luu: Created [Redmine ID: #136460]
        
		Param's Explanation (filtered by):
                
	*/   
    DECLARE v_remark VARCHAR(50);
    DECLARE lv_CreatedBy 		INT;
    DECLARE lv_CurrentDateTime 	DATETIME;
    
    SET  lv_CreatedBy = 10278938;
	SET  lv_CurrentDateTime = NOW();
    
    DROP TEMPORARY TABLE IF EXISTS Tmp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Tmp_ProblemAccounts 
    (	  
			CustID				BIGINT UNSIGNED
        , 	MainDBCategoryID	SMALLINT UNSIGNED
        , 	CategoryID			SMALLINT UNSIGNED
        , 	CTSCustID			BIGINT UNSIGNED DEFAULT NULL
        , 	SubscriberID		INT DEFAULT NULL
        ,	IsNew				BIT DEFAULT 0
        , 	PRIMARY KEY			PK_Tmp_ProblemAccounts_CustID(CustID)  
        ,	INDEX				IX_Tmp_ProblemAccounts_IsNew(IsNew)  
    );     
    
    INSERT INTO Tmp_ProblemAccounts(CustID, MainDBCategoryID)
	SELECT 	t.CustID
		, 	t.MainDBCategoryID
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, MainDBCategoryID	SMALLINT UNSIGNED	PATH "$.CategoryId"	
		 )) AS t;   
	
    SET SQL_SAFE_UPDATES = 0;
    
    UPDATE Tmp_ProblemAccounts
    SET CategoryID = 	CASE 
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
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
	UPDATE Tmp_ProblemAccounts AS t
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c ON t.CustID = c.CustID
	SET	t.IsNew = 1
    WHERE c.CustID IS NULL; 
    
    UPDATE Tmp_ProblemAccounts AS t
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID
	SET		t.CTSCustID = c.CTSCustID
		, 	t.SubscriberID = c.SubscriberID
	WHERE t.IsNew = 1;      	
    
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
		 CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	t.CustID
		, 	t.CTSCustID
		, 	t.SubscriberID
		, 	t.CategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Tmp_ProblemAccounts AS t
    WHERE t.IsNew = 1;            
    
    UPDATE CTS_DataCenter.CTSCustomerClassification AS c
    INNER JOIN Tmp_ProblemAccounts AS t ON	t.CustID = c.CustID
 	SET  	c.CategoryID = t.CategoryID 
		,	c.LastModifiedDate = lv_CurrentDateTime
        , 	c.LastModifiedBy = lv_CreatedBy
        , 	c.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE t.IsNew = 0;
     
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID,
		LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	t.CustID
		, 	t.CTSCustID
		, 	t.CategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	0
		, 	0
		, 	0
		, 	0
		, 	CASE WHEN t.IsNew = 0 THEN 2 ELSE 1 END
		, 	1
		, 	lv_CurrentDateTime AS InsertDate
	FROM 	Tmp_ProblemAccounts AS t;   
	
END$$
DELIMITER ;
