USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_SpecialCustomerClass_InsertRobotUsers`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_SpecialCustomerClass_InsertRobotUsers`( 
     IN ip_CustIDs 	TEXT  
)
BEGIN
    /*
		Created:	Irena.Vo@20200911
		Task:		Insert Robot Customer Class 
		DB:			CTS_DataCenter
		Original:
        
        Revision:
			- Irena.Vo@20200911 [Redmine ID: #141416]: Created. Support for Licensee & 611111 sites 
                
		Param's Explanation (filtered by):
        ip_CustIDs = 1,2,3
                
	*/
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy INT DEFAULT 10278938;
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_SpecialCustomerClass_InsertRobotUsers';
    
    -- Temp Robot User list
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotUsers;
    CREATE TEMPORARY TABLE Temp_RobotUsers(
			CustID	INT UNSIGNED PRIMARY KEY
    );
    
     -- Temp Customer list
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerInfo;
    CREATE TEMPORARY TABLE Temp_CustomerInfo(
			CTSCustID	BIGINT UNSIGNED PRIMARY KEY,
            CustID	INT UNSIGNED,
            SubscriberID INT
    );
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET SQL_SAFE_UPDATES = 0;
  
    -- Insert data from mainDB
    SET @sql = CONCAT("INSERT INTO Temp_RobotUsers(CustID) VALUES ('", REPLACE(ip_CustIDs,",","'),('"),"');");
	PREPARE stm1 FROM @sql;
	EXECUTE stm1;
    
	-- Ignore VVIP & Robot Customer Class
    DELETE temp
    FROM Temp_RobotUsers AS temp
    WHERE temp.CustID IN (SELECT DISTINCT CustID
	                      FROM CTS_DataCenter.SpecialCustomerClass 
						  WHERE CreatedFromFunction = 11 OR (CreatedFromFunction = 1 AND CustomerClass = 13));
  
	-- Delete old Customer Class before.
    DELETE sc
    FROM CTS_DataCenter.SpecialCustomerClass AS sc
    WHERE sc.CustID IN (SELECT DISTINCT CustID FROM Temp_RobotUsers) AND sc.CreatedFromFunction = 1;
    
	-- Get customer info
    INSERT INTO Temp_CustomerInfo
    SELECT DISTINCT CTSCustID, CustID, SubscriberID
    FROM CTS_DataCenter.CTSCustomer 
    WHERE CustID IN (SELECT DISTINCT CustID FROM Temp_RobotUsers) AND CustSubID = 0;    
    
    -- Insert Robot Customer Class
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
	FROM Temp_CustomerInfo; -- Remove all old customer class.
    
    -- Return Robot Customer Class
    SELECT 	DISTINCT CustID
		,	13 AS CustomerClass
	FROM Temp_CustomerInfo;
	
	-- Insert history
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
    SELECT 19, lv_SPName, CONCAT('Insert SpecialCustomerClass: ip_CTSCustID = ', CTSCustID, ';ip_CustomerClass = ', 13), lv_CurrentDateTime, lv_CreatedBy
    FROM Temp_CustomerInfo;

    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

END$$

DELIMITER ;