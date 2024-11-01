/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_UpdateCustInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_UpdateCustInfo`(
		IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20230921@Casey.Huynh
		Task:		Mapping CTSCustomer Info
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 	20230921@Casey.Huynh: Created [Redmine ID: #193050]
                -	20241016@Casey.Huynh: Agency CC, Seperate Member and Agency [Redmine ID: #185799]
                
		Param's Explanation (filtered by):
        
        Example:
				CALL CTS_DataCenter.CTS_DC_CustClassification_UpdateCustInfo('1,2,3');

*/ 
    
	DECLARE lv_CurrentDateTime 			DATETIME DEFAULT CURRENT_TIME();
    
    #=====================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			CustID			INT PRIMARY KEY
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerInfo;
    CREATE TEMPORARY TABLE Temp_CustomerInfo(
			CustID			INT PRIMARY KEY
		,	CTSCustID		BIGINT UNSIGNED
		,	SubscriberID	INT
        ,	RoleID			INT
	);
    
    #=====================================================
    IF ip_CustIDList IS NOT NULL THEN
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;    
	END IF;

    INSERT INTO Temp_CustomerInfo(CustID, CTSCustID, SubscriberID, RoleID)
    SELECT	cus.CustID
		,	cus.CTSCustID
        ,	cus.SubscriberID
        ,	cus.RoleID
    FROM Temp_Customer AS tmp
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID = 0;
        
	/**********UPDATE FOR MEMBER**************************************/
    /* 1: UPDATE CTSCustomerClassification */
	UPDATE CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = cls.CustID AND tmp.RoleID = 1
	SET	cls.CTSCustID = tmp.CTSCustID 
		,	cls.SubscriberID = tmp.SubscriberID
        ,	cls.RoleID = tmp.RoleID;

    /* 2: WRITE HISTORY (VIEW ON WEB) */    
    UPDATE CTS_DataCenter.CTSCustomerClassification_History AS clh
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = clh.CustID AND tmp.RoleID = 1
	SET clh.CTSCustID = tmp.CTSCustID;
    
    UPDATE CTS_DataCenter.CTSCustomerClassification_Log AS cll
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = cll.CustID AND tmp.RoleID = 1
	SET cll.CTSCustID = tmp.CTSCustID;
    
    /**********UPDATE FOR AGENCY**************************************/
	UPDATE CTS_DataCenter.CTSCustomerClassificationAgency AS cls
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = cls.CustID AND tmp.RoleID IN (2,3,4)
	SET cls.CTSCustID = tmp.CTSCustID 
		,	cls.SubscriberID = tmp.SubscriberID
        ,	cls.RoleID = tmp.RoleID;

    /* 2: WRITE HISTORY (VIEW ON WEB) */    
    UPDATE CTS_DataCenter.CTSCustomerClassificationAgency_History AS clh
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = clh.CustID AND tmp.RoleID IN (2,3,4)
	SET	clh.CTSCustID = tmp.CTSCustID
		,	clh.RoleID = tmp.RoleID;
    
    UPDATE CTS_DataCenter.CTSCustomerClassificationAgency_Log AS cll
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = cll.CustID AND tmp.RoleID IN (2,3,4)
	SET cll.CTSCustID = tmp.CTSCustID
		,	cll.RoleID = tmp.RoleID;
END$$
DELIMITER ;