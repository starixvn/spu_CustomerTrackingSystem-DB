DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertNewCustomerCategory $$

CREATE PROCEDURE CTS_DC_InsertNewCustomerCategory (IN ip_CustIds TEXT)
BEGIN
	/*
		Created:	20200703@Long.Luu
		Task:		Insert New-Member category for new accounts [Redmine ID: 136903]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200703@Long.Luu: created [Redmine ID: 136903]
        
		Param's Explanation (filtered by):
	*/

	SET @v_NewAccountCategory = 2;
    SET @v_CreatedBy = 10278938;
    SET @v_CurrentDate = CURRENT_DATE();
    
	DROP TEMPORARY TABLE IF EXISTS TmpNewCustomers;
    
	CREATE TEMPORARY TABLE TmpNewCustomers
	(		
			CustID			INT	 UNSIGNED PRIMARY KEY
        ,	CTSCustID		BIGINT UNSIGNED
        ,	SubscriberID	INT
	);

	# Parse new customers
	SET @sql = CONCAT("INSERT INTO TmpNewCustomers(CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    
    # Remove new customers that have been categorized
    DELETE n
    FROM TmpNewCustomers AS n
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS c ON c.CustID = n.CustID;
        
	# Get customers' info
    UPDATE TmpNewCustomers AS n
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON c.CustID = n.CustID
    SET 	n.CTSCustID = c.CTSCustID
		,	n.SubscriberID = c.SubscriberID;
	
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
          
	# Insert customers' classification
    INSERT INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
			CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	n.CustID
		, 	n.CTSCustID
		, 	n.SubscriberID
		, 	@v_NewAccountCategory
		, 	0
		, 	@v_CurrentDate
		, 	@v_CreatedBy
		, 	@v_CurrentDate
		, 	@v_CreatedBy
		, 	DATE(@v_CurrentDate)
	FROM TmpNewCustomers AS n;   
            
	# Insert  customers' classification to history
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID,
			LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	n.CustID
		, 	n.CTSCustID
		, 	@v_NewAccountCategory
		, 	0
		, 	@v_CurrentDate
		, 	@v_CreatedBy
		, 	0
		, 	0
		, 	0
		, 	0
		, 	0 # insert
		, 	1
		, 	@v_CurrentDate
	FROM TmpNewCustomers AS n;   
END$$
DELIMITER ;