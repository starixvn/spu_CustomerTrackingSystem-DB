DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_CheckCustNotExistedByCustIds $$
/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE CTS_DataCenter.CTS_DC_CustInfo_CheckCustNotExistedByCustIds(
		  IN ip_CustIDList VARCHAR(2000)
		, IN ip_FromDate DATETIME
		, IN ip_ToDate DATETIME)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201002@Harvey.Nguyen
		Task :		Check customer if they are existed in CTSCustomer
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Long.Luu: Created [Redmine ID: 139701]
			- 20201016@Aries.Nguyen: Enhance performane and fix issue a custId have 2 accountId
            - 20201016@Casey.Huynh: Enhance SP. Return More Info and Remove SubscriberID IN(....)
		
		Param's Explanation (filtered by):
        
        call CTS_DC_CustInfo_CheckCustNotExistedByCustIds("72,1261,1262,1264","2020-09-28 00:00:00.0000","2020-09-28 00:00:00.0000");
	*/
    IF ip_ToDate < NOW() THEN
        SET ip_ToDate = DATE_ADD(NOW(), INTERVAL 1 HOUR);
    END IF;
    
    DROP TEMPORARY TABLE IF EXISTS TempCustomer;
    CREATE TEMPORARY TABLE TempCustomer(
			CustID 	INT PRIMARY KEY
	);   
    
    DROP TEMPORARY TABLE IF EXISTS TempCustomer_Trans; -- Table store cust has transId
	CREATE TEMPORARY TABLE TempCustomer_Trans(
		CustID 	INT
        , SubscriberID INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS TempCustomer_Subscriber; -- Table store cust has transId
	CREATE TEMPORARY TABLE TempCustomer_Subscriber(
		CustID 			INT,
        CTSCustID 		INT,
        UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI',
        UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI',
        SubscriberID 	INT,
        DCSAccountID	BIGINT
	);


    SET @sql = CONCAT("INSERT INTO TempCustomer (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
    INSERT INTO TempCustomer_Subscriber(CustID, CTSCustID, UserName,UserName2, SubscriberID, DCSAccountID)
	SELECT 		tcust.CustID, cust.CTSCustID, cust.UserName, cust.UserName2,cust.SubscriberID, cusAcc.AccountID
	FROM 		TempCustomer tcust
	LEFT JOIN 	CTS_DataCenter.CTSCustomer cust 
				ON tcust.CustID = cust.CustID AND cust.CustSubID = 0
	LEFT JOIN 	CTS_DataCenter.CustDCSAccount cusAcc 
				ON cusAcc.SubscriberID = cust.SubscriberID AND cusAcc.CTSCustID = cust.CTSCustID;
#	WHERE   	cust.SubscriberID IN (2,6,112,116,121,122,130,138,142,165,166,168,169,189,220,221,2338,2339,2364,2372,13659);   
    
    
    INSERT INTO TempCustomer_Trans
	SELECT 		cus.CustID, cus.SubscriberID
	FROM 		TempCustomer_Subscriber AS cus
    INNER JOIN 	DCS_DataCenter.Account 	AS acc 
				ON acc.AccountID = cus.DCSAccountID
    WHERE 		acc.LastLoginTime BETWEEN ip_FromDate AND ip_ToDate;

    SELECT 		temp_cs.CustID
				, temp_cs.CTSCustID
                , temp_cs.UserName
                , temp_cs.UserName2
                , temp_cs.SubscriberID
				, sub.SubscriberName
                , temp_cs.DCSAccountID
    FROM 		TempCustomer_Subscriber AS temp_cs
	LEFT JOIN	CTS_Admin.Subscriber AS sub
				ON temp_cs.SubscriberID = sub.SubscriberID
    WHERE 		CustID NOT IN (SELECT  CustID FROM TempCustomer_Trans);
    
    DROP TEMPORARY TABLE TempCustomer;
	DROP TEMPORARY TABLE TempCustomer_Subscriber;
    DROP TEMPORARY TABLE TempCustomer_Trans;
    
    /*SELECT tcust.CustID
	FROM TempCustomer tcust
		LEFT JOIN CTS_DataCenter.CTSCustomer cust ON tcust.CustID = cust.CustID AND cust.CustSubID = 0
		LEFT JOIN CTS_DataCenter.CustDCSAccount cusAcc ON cusAcc.SubscriberID = cust.SubscriberID AND cusAcc.CTSCustID = cust.CTSCustID
		LEFT JOIN DCS_DataCenter.Transaction07 tran ON  tran.SubscriberID = cusAcc.SubscriberID
			AND tran.AccountID = cusAcc.AccountID 
			AND tran.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
    WHERE tran.AccountID IS NULL AND cust.SubscriberID IN (2,6,112,116,121,122,130,138,142,165,166,168,169,189,220,221,2338,2339,2364,2372,13659); */    
    
END$$
DELIMITER ;
