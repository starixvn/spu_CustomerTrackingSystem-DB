/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_GetByNameSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_GetByNameSubscriber`(
		IN ip_SubscriberID		INT
	,	IN ip_UserNameList		TEXT       
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230601@Casey.Huynh
		Task :		Search Customer by UserName in subscribers
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230601@Casey.Huynh: Created [Redmine ID: 185787]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL CTS_DC_CustInfo_GetByNameSubscriber(@ip_SubscriberID:=6,@ip_NameList:='12Bet-Collection USD,12Bet12MoonstoneTransUS$,12BETAFF1287CashOut,12BETAUD01042,mummy');

	*/   
	DROP TEMPORARY TABLE IF EXISTS Temp_UserName;
    CREATE TEMPORARY TABLE Temp_UserName(
			UserName 	VARCHAR(100)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			UserName		VARCHAR(50)  PRIMARY KEY
        ,	RegisterName	VARCHAR(50)
        ,	CTSCustID		BIGINT UNSIGNED
        ,	SubscriberID	INT
        
	);
    
	#============================================
	SET @sql = CONCAT("INSERT INTO Temp_UserName (UserName) VALUES ('", REPLACE(ip_UserNameList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
	#========SEARCH BY USERNAME2=====================
	INSERT IGNORE INTO Temp_Customer (CTSCustID, Username, RegisterName, SubscriberID)
    SELECT	cus.CTSCustID
		,	cus.Username
        ,	cus.RegisterName
        ,	cus.SubscriberID
    FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN Temp_UserName AS tmp ON cus.SubscriberID = ip_SubscriberID AND tmp.UserName = cus.RegisterName AND cus.IsInternal = 0;
        
    DELETE tmpNm
    FROM Temp_UserName AS tmpNm
		INNER JOIN Temp_Customer AS tmpCus ON tmpNm.UserName = tmpCus.UserName;
        
	#========SEARCH BY USERNAME=====================
    INSERT INTO Temp_Customer (CTSCustID, Username, RegisterName, SubscriberID)
    SELECT	cus.CTSCustID
		,	cus.Username
        ,	cus.RegisterName
        ,	cus.SubscriberID
    FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN Temp_UserName AS tmp ON cus.SubscriberID = ip_SubscriberID AND tmp.UserName = cus.UserName AND cus.IsInternal = 0;
    
    SELECT	tmpCus.CTSCustID
		,	tmpCus.Username
        ,	tmpCus.RegisterName
        ,	tmpCus.SubscriberID
    FROM Temp_Customer AS tmpCus;
    
END$$
DELIMITER ;
