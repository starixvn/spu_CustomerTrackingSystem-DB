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
				- 20230921@Casey.Huynh: Created [Redmine ID: #193050]
                
		Param's Explanation (filtered by):
        
        Example:
				- CALL CTS_DataCenter.CTS_DC_CustClassification_UpdateCustInfo_xtest('1,2,3');
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
	);
    
    #=====================================================
    IF ip_CustIDList IS NOT NULL THEN
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;    
	END IF;

    INSERT INTO Temp_CustomerInfo(CustID, CTSCustID, SubscriberID)
    SELECT	cus.CustID
		,	cus.CTSCustID
        ,	cus.SubscriberID
    FROM Temp_Customer AS tmp
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID = 0;

    /* 1: UPDATE CTSCustomerClassification */
	UPDATE CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = cls.CustID
	SET cls.CTSCustID = tmp.CTSCustID 
		, cls.SubscriberID = tmp.SubscriberID;

    /* 2: WRITE HISTORY (VIEW ON WEB) */    
    UPDATE CTS_DataCenter.CTSCustomerClassification_History AS clh
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = clh.CustID
	SET clh.CTSCustID = tmp.CTSCustID;
    
    UPDATE CTS_DataCenter.CTSCustomerClassification_Log AS cll
		INNER JOIN Temp_CustomerInfo AS tmp ON tmp.CustID = cll.CustID
	SET cll.CTSCustID = tmp.CTSCustID;
    
END$$
DELIMITER ;