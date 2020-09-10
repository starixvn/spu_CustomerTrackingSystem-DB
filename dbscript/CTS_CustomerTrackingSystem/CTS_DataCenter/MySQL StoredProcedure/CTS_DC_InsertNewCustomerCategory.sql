USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertNewCustomerCategory`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertNewCustomerCategory`(IN ip_CustIds TEXT)
BEGIN
	/*
		Created:	20200703@Long.Luu
		Task:		Insert New-Member category for new accounts [Redmine ID: 136903]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200703@Long.Luu: created [Redmine ID: 136903]
            - 20200908@Irena.Vo: Enhance ignore VVIP & Pin category [Redmine ID: 141020]
        
		Param's Explanation (filtered by):
	*/
    DECLARE lv_CreatedBy INT DEFAULT 10278938;
	DECLARE lv_CurrentDate DATETIME DEFAULT CURRENT_DATE(); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewCustomers;
	CREATE TEMPORARY TABLE Temp_NewCustomers
	(		
            CustID			INT	 UNSIGNED PRIMARY KEY
        ,	CTSCustID		BIGINT UNSIGNED
        ,	SubscriberID	INT
	);

	# Parse new customers
	SET @sql = CONCAT("INSERT INTO Temp_NewCustomers(CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    SET SQL_SAFE_UPDATES = 0;
    
    -- Ignore VVIP, Pin Category before
    DELETE temp
    FROM Temp_NewClassification AS temp
        INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID
	WHERE sc.CreatedFromFunction IN (11, 21);
    
    # Remove new customers that have been categorized
    DELETE temp
    FROM Temp_NewCustomers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID;
        
	# Get customers' info
    UPDATE Temp_NewCustomers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cate ON cate.CustID = temp.CustID
    SET 	temp.CTSCustID = cate.CTSCustID
		,	temp.SubscriberID = cate.SubscriberID;
          
	# Insert customers' classification
    INSERT INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
			CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	CustID
		, 	CTSCustID
		, 	SubscriberID
		, 	2 -- New Customer
		, 	0
		, 	lv_CurrentDate
		, 	lv_CreatedBy
		, 	lv_CurrentDate
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDate)
	FROM Temp_NewCustomers;   
            
	# Insert  customers' classification to history
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID,
			LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	CustID
		, 	CTSCustID
		, 	2 -- New Customer
		, 	0
		, 	lv_CurrentDate
		, 	lv_CreatedBy
		, 	0
		, 	0
		, 	0
		, 	0
		, 	0 # insert
		, 	1
		, 	DATE(lv_CurrentDate)
	FROM Temp_NewCustomers;   
    
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$

DELIMITER ;