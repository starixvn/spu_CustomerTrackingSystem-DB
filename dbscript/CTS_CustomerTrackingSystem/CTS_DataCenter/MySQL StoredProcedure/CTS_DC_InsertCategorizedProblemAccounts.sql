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
    DECLARE v_createdBy INT;
    DECLARE v_LastScannedDate DATETIME;
    
    SET  v_createdBy = 1027893;
	SET  v_LastScannedDate = CURRENT_DATE();
    
    DROP TEMPORARY TABLE IF EXISTS Tmp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Tmp_ProblemAccounts 
    (	  
		  CustID			BIGINT UNSIGNED
        , CategoryID		SMALLINT UNSIGNED
        , CTSCustID			BIGINT UNSIGNED DEFAULT NULL
        , SubscriberID		INT DEFAULT NULL   
        , PRIMARY KEY		PK_Tmp_ProblemAccounts_CustID(CustID)      
    );     
    
    INSERT INTO Tmp_ProblemAccounts(CustID, CategoryID)
	SELECT 	tmpTable.CustID
		, 	tmpTable.CategoryID
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"	
		 )) AS tmpTable;   
	
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
    UPDATE Tmp_ProblemAccounts AS t
    INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID
	SET	t.CTSCustID = c.CTSCustID
		, t.SubscriberID = c.SubscriberID;
      
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
				 CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 
			tmpCla.CustID
			, tmpCla.CTSCustID
			, tmpCla.SubscriberID
			, tmpCla.CategoryID
			, tmpCla.SportGroupID
			, tmpCla.LastModifiedDate
			, v_createdBy
			, tmpCla.LastModifiedDate
			, v_createdBy
            , DATE(tmpCla.LastModifiedDate)	AS LastScannedDate
	FROM 	Tmp_ProblemAccounts 		AS tmpCla
	WHERE 	tmpCla.ActionType IN (0,-1)
			AND tmpCla.CategoryId != 0;   
            
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN 	Tmp_ProblemAccounts AS tmpCla 
				ON 	tmpCla.CustID = ccl.CustID		
				AND tmpCla.SportGroupID = ccl.SportGroupID
 	SET  ccl.CategoryID = tmpCla.CategoryID
        , ccl.LastModifiedDate = tmpCla.LastModifiedDate 
        , ccl.LastModifiedBy = v_createdBy
        , ccl.LastScannedDate = GREATEST(DATE(tmpCla.LastModifiedDate),ccl.LastScannedDate)
	WHERE tmpCla.ActionType = 1;
     
     
    #======= INSERT Customer Classification History
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID
					,SportGroupID ,LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	tmpCla.CustID
			, tmpCla.CTSCustID
			, tmpCla.CategoryID
            , tmpCla.SportGroupID
            , tmpCla.LastModifiedDate
            , v_createdBy
            , TurnoverRM
            , WinlossRM
            , BetCount
            , ActiveDays
			, tmpCla.ActionType
            , 1
            , CURRENT_DATE() AS InsertDate
	FROM 	Tmp_ProblemAccounts AS tmpCla
    WHERE	tmpCla.ActionType IN (-1, 0, 1);   
	
END$$
DELIMITER ;
