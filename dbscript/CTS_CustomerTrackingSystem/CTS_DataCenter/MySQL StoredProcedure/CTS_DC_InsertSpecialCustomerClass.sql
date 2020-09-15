USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertSpecialCustomerClass`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertSpecialCustomerClass`(
		IN ip_Username 					VARCHAR(50)     
    ,	IN ip_CustomerClass 			TINYINT 
    ,	IN ip_IsAffectedToAssociation	BIT
    ,	IN ip_UserID 					INT
    
    , 	OUT op_ErrorMessage 			VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200905@Long.Luu
		Task:		Insert special customer class 
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200905@Long.Luu [140996]: Created
           - 20200908@Irena.Vo [141020]: Error MSG for the customers have VVIP before and Update CreatedFromFunction = 1 for special customer (Normal)
           
		Param's Explanation (filtered by):
	*/    
      
	DECLARE lv_CTSCustID		BIGINT UNSIGNED;
    DECLARE lv_CustID			INT UNSIGNED;
	DECLARE lv_SubscriberID 	INT;
    DECLARE	lv_CurrentDateTime	DATETIME DEFAULT NOW();
    DECLARE	lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_InsertSpecialCustomerClass';        
    
    # Handle error
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;        
        SELECT NULL AS CustID,	NULL AS CustomerClass;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedCustomers;    
	CREATE TEMPORARY TABLE Temp_AffectedCustomers 
    (	 
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
    );    
    
    DROP TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			DCSDeviceID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TABLE IF EXISTS Temp_AssociationException;
    CREATE TEMPORARY TABLE Temp_AssociationException(
			CTSCustID 	BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TABLE IF EXISTS Temp_NewCustomerClass;
    CREATE TEMPORARY TABLE Temp_NewCustomerClass(
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
		,	CustID			INT UNSIGNED
        ,	SubscriberID	INT
        ,	CustomerClass	SMALLINT
	);
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET SQL_SAFE_UPDATES = 0;
   
    -- Check invalid customer in CTS.
    IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer WHERE UserName = ip_Username OR UserName2 = ip_Username) THEN
		SET op_ErrorMessage = 'This account is not existed in the system!';
        SELECT NULL AS CustID,	NULL AS CustomerClass;
        LEAVE sp;
	END IF;
    
    -- #1: get customer info
    SELECT CTSCustID, CustID, SubscriberID
    INTO lv_CTSCustID, lv_CustID, lv_SubscriberID
    FROM CTS_DataCenter.CTSCustomer 
    WHERE UserName = ip_Username OR UserName2 = ip_Username;    
    
     -- Existed VVIP CustomerClass before -> Display error message
	IF EXISTS (SELECT 1 FROM CTS_DataCenter.SpecialCustomerClass WHERE CTSCustID = lv_CTSCustID AND CreatedFromFunction = 11) THEN
		SET op_ErrorMessage = 'This account has already been marked with VVIP CustomerClass!';
		SELECT NULL AS CustID,	NULL AS CustomerClass;
        LEAVE sp;
	END IF;
	-- Existed CustomerClass before
	IF EXISTS (SELECT 1 FROM CTS_DataCenter.SpecialCustomerClass WHERE CTSCustID = lv_CTSCustID AND CreatedFromFunction = 1) THEN
		SET op_ErrorMessage = 'This account has already been marked with a CustomerClass!';    
        SELECT NULL AS CustID,	NULL AS CustomerClass;
        LEAVE sp;
	END IF;
    
	-- #2: get affected customers
	INSERT INTO Temp_AffectedCustomers(CTSCustID)
	VALUES(lv_CTSCustID);
	
	IF (ip_IsAffectedToAssociation = 1) THEN
		# 2.1: get affected devices
		INSERT INTO Temp_AffectedDevices(DCSDeviceID)
		SELECT DISTINCT a.DCSDeviceID
		FROM CTS_DataCenter.AssociationByDevice AS a    
		WHERE a.CTSCustID = lv_CTSCustID;
		
		# 2.2: get association exception
		INSERT INTO Temp_AssociationException(CTSCustID)
		SELECT DISTINCT (CASE WHEN e.LeastCTSCustID_Order <> lv_CTSCustID THEN e.LeastCTSCustID_Order ELSE e.GreatestCTSCustID_Order END)
		FROM CTS_DataCenter.CustException AS e
		WHERE e.LeastCTSCustID_Order = lv_CTSCustID OR e.GreatestCTSCustID_Order = lv_CTSCustID;
				   
		# 2.3: get affected ones
		INSERT INTO Temp_AffectedCustomers(CTSCustID)
		SELECT DISTINCT a.CTSCustID
		FROM Temp_AffectedDevices AS d
			INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
			LEFT JOIN Temp_AssociationException AS e ON a.CTSCustID = e.CTSCustID
		WHERE a.SubscriberID = lv_SubscriberID
			AND a.CTSCustID <> lv_CTSCustID
			AND e.CTSCustID IS NULL;
	END IF;

	INSERT INTO Temp_NewCustomerClass(CTSCustID, CustID, SubscriberID, CustomerClass)
	SELECT 	DISTINCT t.CTSCustID
		,	c.CustID
		,	lv_SubscriberID
		,	ip_CustomerClass
	FROM Temp_AffectedCustomers AS t
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS s ON t.CTSCustID = s.CTSCustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID
	WHERE s.CTSCustID IS NULL OR (s.CreatedFromFunction = 21) -- Allow Pin category will insert new CustomerClass
		AND c.RoleID = 1;
	
	INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
	SELECT 	CTSCustID
		,	CustID
		,	lv_CTSCustID
		,	SubscriberID
		,	CustomerClass
		,	ip_UserID
		,	lv_CurrentDateTime
		,	ip_UserID
		,	lv_CurrentDateTime
		,   1 -- for Special Customer
	FROM Temp_NewCustomerClass;
	
	SELECT 	DISTINCT CustID
		,	CustomerClass
	FROM Temp_NewCustomerClass;
	
	# Logging
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(19, lv_SPName, CONCAT('Insert SpecialCustomerClass: ip_CTSCustID = ', lv_CTSCustID, ';ip_CustomerClass = ', ip_CustomerClass), lv_CurrentDateTime, ip_UserID);

    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$

DELIMITER ;