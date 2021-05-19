/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetWithCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetWithCategory`(IN ip_CustIDList VARCHAR(8000), IN ip_IsDelete BOOLEAN)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201027@Harvey
		Task :		Get Association and Category (support data for Soon88)
		DB:			CTS_DataCenter
		Original:

		Revisions:
        - 20201027@Harvey: Init SPs. Association: only get association by device
		- 20210317@Irena.Vo: Review logic get data & update syntax. [RedmineID: #151374]

		Param's Explanation (filtered by):
        *** pre-condition: RegisterName is not null & Category is PA, Smart Punter, High Risk Punter.   
			call CTS_DataCenter.CTS_DC_Association_GetWithCategory('41609149,41611983,41630670', 0);
	*/
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
    CREATE TEMPORARY TABLE Temp_Customers (
			CustID 			INT 	UNSIGNED PRIMARY KEY,
            CTSCustID		BIGINT	UNSIGNED,
            RegisterName 	VARCHAR(50),
            CategoryName	VARCHAR(50)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Results;
    CREATE TEMPORARY TABLE Temp_Results (
            RegisterName 	VARCHAR(50),
            CategoryName	VARCHAR(50),
            AssRegisterName VARCHAR(50),
            AssCategoryName	VARCHAR(50),
            IsSoon88		BOOLEAN
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_DevLv1;
    CREATE TEMPORARY TABLE Temp_DevLv1 (
			DCSDeviceID 	BIGINT 	UNSIGNED,
            CTSCustID		BIGINT	UNSIGNED
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    /* GET CATEGORY LIST FOR SOON88 */
    UPDATE Temp_Customers AS tcust
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tcust.CustID = cus.CustID AND cus.CustSubID = 0
        INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = cus.SubscriberID AND sub.SubscriberName = 'Soon88'
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS class ON tcust.CustID = class.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS custCate ON class.CategoryID = custCate.CategoryID
	SET 	tcust.CTSCustID = cus.CTSCustID
		,	tcust.RegisterName = TRIM(LEADING 'S88' FROM cus.RegisterName)
		,	tcust.CategoryName = custCate.CategoryName
	WHERE custCate.ParentID = 50 OR custCate.CategoryID IN (203,204);
    
	/* IGNORE CUSTOMER IS NOT IN CTS */
    DELETE FROM Temp_Customers WHERE CTSCustID IS NULL;
    
    /* GET RESULT */
    /* Is remove category */
    IF ip_IsDelete THEN
		SELECT RegisterName, CategoryName FROM Temp_Customers;
    
	/* Is get category */
    ELSE
		INSERT INTO Temp_DevLv1 (CTSCustID, DCSDeviceID)
		SELECT tcust.CTSCustID,	ass.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS ass
			RIGHT JOIN Temp_Customers AS tcust ON tcust.CTSCustID = ass.CTSCustID; /* Get Association By Device */
        
        INSERT INTO Temp_Results(RegisterName,CategoryName)
        SELECT tcust.RegisterName, tcust.CategoryName
        FROM Temp_Customers AS tcust 
			INNER JOIN Temp_DevLv1 AS dev ON tcust.CTSCustID = dev.CTSCustID
        WHERE dev.DCSDeviceID IS NULL AND tcust.RegisterName IS NOT NULL; /* For Root Account */
        
        DELETE FROM Temp_DevLv1 WHERE DCSDeviceID IS NULL;
        
        INSERT INTO Temp_Results(RegisterName,CategoryName, AssRegisterName, AssCategoryName, IsSoon88)
		SELECT 	tcust.RegisterName
            ,	tcust.CategoryName
			,	TRIM(LEADING 'S88' FROM cust.RegisterName) 'AssRegisterName'
			,	CASE 
					WHEN custCate.CategoryID IN (203,204) THEN custCate.CategoryName
					WHEN custCate.ParentID = 50 THEN custCate.CategoryName
					ELSE 'Normal' 
				END 'AssCategoryName'
			,	CASE 
					WHEN sub.SubscriberName = 'Soon88' THEN 1
					ELSE 0
				END 'IsSoon88'
		FROM Temp_Customers AS tcust
			INNER JOIN Temp_DevLv1 AS dev ON tcust.CTSCustID = dev.CTSCustID
			LEFT JOIN CTS_DataCenter.AssociationByDevice AS ass ON dev.DCSDeviceID = ass.DCSDeviceID AND dev.CTSCustID <> ass.CTSCustID
			LEFT JOIN CTS_DataCenter.CTSCustomer AS cust ON ass.CTSCustID = cust.CTSCustID
			LEFT JOIN CTS_Admin.Subscriber AS sub ON cust.SubscriberID = sub.SubscriberID
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS class ON ass.CTSCustID = class.CTSCustID
			LEFT JOIN CTS_DataCenter.CustomerCategory AS custCate ON class.CategoryID = custCate.CategoryID AND custCate.ParentID IN (50,200);
            
		SELECT DISTINCT * FROM Temp_Results;
    END IF;
END$$
DELIMITER ;
