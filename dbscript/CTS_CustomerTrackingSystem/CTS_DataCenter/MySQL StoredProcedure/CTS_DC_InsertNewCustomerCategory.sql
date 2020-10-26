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
			[20200703@Long.Luu][136903]: created
            [20200908@Irena.Vo][141020]: Enhance ignore VVIP & Pin category 
            [20200923-20201001@Irena.Vo][141755]: 
            - Enhance SP
            - Covered get Existed Category before
            - Fix issue duplicate category
            [20201003-20201026@Irena.Vo][142546]: Enhance SP & correct logic. 
            
		Param's Explanation (filtered by):
             call CTS_DC_InsertNewCustomerCategory('1,2,3');
	*/
    DECLARE lv_CreatedBy INT DEFAULT 10278938; 
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewCustomers;
	CREATE TEMPORARY TABLE Temp_NewCustomers
	(		
            CustID			BIGINT UNSIGNED PRIMARY KEY
        ,	CTSCustID		BIGINT UNSIGNED
        ,	SubscriberID	INT
        ,   INDEX 			IX_Temp_NewCustomers_CustID(CustID)       
	);
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification 
	(	  CustID			BIGINT UNSIGNED        
        , INDEX 			IX_Temp_ExistedClassification_CustID(CustID)       
     );
     
	SET @sql = CONCAT("INSERT INTO Temp_NewCustomers(CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    SET SQL_SAFE_UPDATES = 0;
    
   	/*IGNORE VVIP - PIN CATEGORY*/
    DELETE temp
	FROM Temp_NewCustomers AS temp
	INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID -- is VVIP OR PIN
	WHERE sc.CreatedFromFunction IN (11, 21);
    
    /*GET EXISTED CATEGORY*/
    INSERT INTO Temp_ExistedClassification
    SELECT cate.CustID
    FROM Temp_NewCustomers AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    WHERE cc.ParentID IN (1, 50); 
    
	/*IGNORE CUSTOMER HAS CATEGORY BEFORE*/
    DELETE temp
    FROM Temp_NewCustomers AS temp
    INNER JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID;
    
   /*UPDATE CUST INFO*/
    UPDATE 	Temp_NewCustomers AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID; 
     
	/*INSERT NEW MEMBER CATEGORY*/
    INSERT INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
			CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	2
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM Temp_NewCustomers AS temp;
            
	/*INSERT LOG*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID,
			LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	2
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	0
		, 	0
		, 	0
		, 	0
		, 	0
		, 	1
		, 	CURRENT_DATE()
	FROM Temp_NewCustomers AS temp;
    
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewCustomers; 
    
END$$

DELIMITER ;