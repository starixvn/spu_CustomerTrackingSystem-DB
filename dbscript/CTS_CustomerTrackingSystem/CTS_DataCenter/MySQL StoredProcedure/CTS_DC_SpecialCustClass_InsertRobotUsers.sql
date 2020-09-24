USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_InsertRobotUsers`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_SpecialCustClass_InsertRobotUsers`(
     IN ip_CustIDs 	TEXT  
)
BEGIN
    /*
		Created:	Irena.Vo@20200911
		Task:		Insert Robot Customer Class 
		DB:			CTS_DataCenter
		Original:
        
        Revision:
			- [20200911@Irena.Vo][141416]: Created. Support for Licensee & 611111 sites 
            - [20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow.    
			- [20200923@Irena.Vo][141755]: Enhance SP
            
		Param's Explanation (filtered by):
        ip_CustIDs = 1,2,3
                
	*/
    /**********1. PREPARE PARAMS**********/
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT NOW();
    DECLARE lv_CreatedBy INT DEFAULT 10278938;
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_SpecialCustClass_InsertRobotUsers';
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotUsers;
    CREATE TEMPORARY TABLE Temp_RobotUsers(
			CustID	INT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerInfo;
    CREATE TEMPORARY TABLE Temp_CustomerInfo(
			CTSCustID	BIGINT UNSIGNED PRIMARY KEY,
            CustID	INT UNSIGNED,
            SubscriberID INT
    );
    
    SET @sql = CONCAT("INSERT INTO Temp_RobotUsers(CustID) VALUES ('", REPLACE(ip_CustIDs,",","'),('"),"');");
	PREPARE stm1 FROM @sql;
	EXECUTE stm1;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET SQL_SAFE_UPDATES = 0;
    
    /**********2. IGNORE VVIP & ROBOT BEFORE**********/
    DELETE temp
    FROM Temp_RobotUsers AS temp 
    INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
    WHERE sc.CreatedFromFunction = 11 OR (sc.CreatedFromFunction = 1 AND sc.CustomerClass = 13);
   
	/**********3. DELETE SPECIAL CUSTOMER CLASS BEFORE**********/
    DELETE sc
    FROM CTS_DataCenter.SpecialCustomerClass AS sc
    INNER JOIN Temp_RobotUsers AS temp ON temp.CustID = sc.CustID
    WHERE sc.CreatedFromFunction = 1;
    
    /**********4. DELETE PROBATION LIST BEFORE**********/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_RobotUsers AS temp ON temp.CustID = pro.CustID;
    
	/**********5. GET CUST INFO**********/
    INSERT INTO Temp_CustomerInfo
    SELECT cust.CTSCustID, cust.CustID, cust.SubscriberID
    FROM CTS_DataCenter.CTSCustomer AS cust
    INNER JOIN Temp_RobotUsers AS temp ON temp.CustID = cust.CustID AND cust.CustSubID = 0;
    
    /**********6. INSERT ROBOT CUSTOMER CLASS**********/
    INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
	SELECT 	CTSCustID
		,	CustID
		,	CTSCustID
		,	SubscriberID
		,	13
		,	lv_CreatedBy
		,	lv_CurrentDateTime
		,	lv_CreatedBy
		,	lv_CurrentDateTime
		,   1 -- For Special Customer
	FROM Temp_CustomerInfo;
    
    SELECT 	DISTINCT CustID
		,	13 AS CustomerClass
	FROM Temp_CustomerInfo;
	
	/**********7. INSERT HISTORY**********/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
    SELECT 19, lv_SPName, CONCAT('Insert SpecialCustomerClass: ip_CTSCustID = ', CTSCustID, ';ip_CustomerClass = ', 13), lv_CurrentDateTime, lv_CreatedBy
    FROM Temp_CustomerInfo;

    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerInfo;
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotUsers; 
END$$

DELIMITER ;