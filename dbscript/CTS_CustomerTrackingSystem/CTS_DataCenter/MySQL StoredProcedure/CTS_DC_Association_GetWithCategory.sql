DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DC_Association_GetWithCategory $$

CREATE DEFINER=`ctsService`@`%` PROCEDURE `CTS_DC_Association_GetWithCategory`(IN ip_CustIDList VARCHAR(2000))
BEGIN
	/*
		Created:	20201027@Harvey
		Task :		Get Association and Category (support data for Soon88)
		DB:			CTS_DataCenter
		Original:

		Revisions:
        - 20201027@Harvey: Init SPs. Association: only get association by device

		Param's Explanation (filtered by):
        
			call CTS_DataCenter.CTS_DC_Association_GetWithCategory('443153');
	*/
	
	DROP TEMPORARY TABLE IF EXISTS TempCustomers;
    CREATE TEMPORARY TABLE TempCustomers (
			CustID 			INT 	UNSIGNED PRIMARY KEY,
            CTSCustID		BIGINT	UNSIGNED,
            RegisterName 	VARCHAR(50),
            CategoryName	VARCHAR(50)
    );
 /*   
    DROP TEMPORARY TABLE IF EXISTS Results;
    CREATE TEMPORARY TABLE Results (
            RegisterName 	VARCHAR(50),
            CategoryName	VARCHAR(50),
            AssRegisterName VARCHAR(50),
            AssCategoryName	VARCHAR(50),
            IsSoon88		BOOLEAN
    );
    */
    
    DROP TEMPORARY TABLE IF EXISTS DevLv1;
    CREATE TEMPORARY TABLE DevLv1 (
			DCSDeviceID 	BIGINT 	UNSIGNED,
            CTSCustID		BIGINT	UNSIGNED
    );
    
	SET @sql = CONCAT("INSERT INTO TempCustomers (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    UPDATE TempCustomers tcust
		INNER JOIN CTS_DataCenter.CTSCustomer cus ON tcust.CustID = cus.CustID
			AND cus.CustSubID = 0
		INNER JOIN CTS_DataCenter.CTSCustomerClassification class ON tcust.CustID = class.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory custCate ON class.CategoryID = custCate.CategoryID
	SET tcust.CTSCustID = cus.CTSCustID
		,tcust.RegisterName = TRIM(LEADING 'S88' FROM cus.RegisterName)
		,tcust.CategoryName = custCate.CategoryName
	WHERE custCate.ParentID IN (50,200);
    
    DELETE FROM TempCustomers
    WHERE CTSCustID IS NULL;
    
    INSERT INTO DevLv1 (
			CTSCustID
		,	DCSDeviceID
		)
	SELECT ass.CTSCustID
		,ass.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice ass
	INNER JOIN TempCustomers tcust ON tcust.CTSCustID = ass.CTSCustID;
        
	SELECT tcust.RegisterName
		,tcust.CategoryName
		,TRIM(LEADING 'S88' FROM cust.RegisterName) 'AssRegisterName'
        ,custCate.CategoryID 'AssCategoryId'
        ,CASE 
			WHEN custCate.CategoryID IN (203,204) THEN custCate.CategoryName
            WHEN custCate.ParentID = 50 THEN custCate.CategoryName
            ELSE 'Normal' 
		 END 'AssCategoryName'
		,CASE 
			WHEN sub.SubscriberName = 'Soon88'
				THEN 1
			ELSE 0
			END 'IsSoon88'
	FROM DevLv1 dev
		INNER JOIN TempCustomers tcust ON tcust.CTSCustID = dev.CTSCustID
		LEFT JOIN CTS_DataCenter.AssociationByDevice ass ON dev.DCSDeviceID = ass.DCSDeviceID
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON ass.CTSCustID = cust.CTSCustID
		INNER JOIN CTS_Admin.Subscriber sub ON cust.SubscriberID = sub.SubscriberID
		INNER JOIN CTS_DataCenter.CTSCustomerClassification class ON ass.CTSCustID = class.CTSCustID
		INNER JOIN CTS_DataCenter.CustomerCategory custCate ON class.CategoryID = custCate.CategoryID
	WHERE dev.CTSCustID <> ass.CTSCustID
		AND custCate.ParentID IN (50,200);

END$$
DELIMITER ;
