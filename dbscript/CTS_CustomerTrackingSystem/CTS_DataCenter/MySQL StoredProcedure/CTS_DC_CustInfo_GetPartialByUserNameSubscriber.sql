/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_GetPartialByUserNameSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_GetPartialByUserNameSubscriber`(
		IN ip_SubscriberID		INT
	,	IN ip_UserName			VARCHAR(50)
	,	IN ip_Skip				INT
    ,	IN ip_Take				INT
    ,	OUT	op_TotalItem		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230601@Casey.Huynh
		Task :		Search parital Customer by UserName in subscribers
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230601@Casey.Huynh: Created [Redmine ID: 185787]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL CTS_DC_CustInfo_GetPartialByUserNameSubscriber(@ip_SubscriberID:=6,@ip_NameList:='12Bet', @ip_Skip:=0, @ip_Take:=10, @op_TotalItem); SELECT @op_TotalItem;

	*/   
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			UserName		VARCHAR(50)  PRIMARY KEY
        ,	RegisterName	VARCHAR(50)
        ,	CTSCustID		BIGINT UNSIGNED
        ,	SubscriberID	INT
        
	);
    
	#============================================
	SET @sql = CONCAT("INSERT INTO Temp_UserName (UserName) VALUES ('", REPLACE(ip_UserName, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

    #========SEARCH BY USERNAME=====================
    INSERT INTO Temp_Customer (CTSCustID, Username, RegisterName, SubscriberID)
    SELECT	cus.CTSCustID
		,	cus.Username
        ,	cus.RegisterName
        ,	cus.SubscriberID
    FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN Temp_UserName AS tmp ON  cus.SubscriberID = ip_SubscriberID AND cus.UserName LIKE CONCAT('%',tmp.UserName,'%') ;
        
	#========SEARCH BY USERNAME2=====================
	INSERT IGNORE INTO Temp_Customer (CTSCustID, Username, RegisterName, SubscriberID)
    SELECT	cus.CTSCustID
		,	cus.Username
        ,	cus.RegisterName
        ,	cus.SubscriberID
    FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN Temp_UserName AS tmp ON cus.SubscriberID = ip_SubscriberID AND cus.UserName2 LIKE CONCAT('%',tmp.UserName,'%') ;
    
    SET op_TotalItem = (SELECT COUNT(1) FROM Temp_Customer);
    
    SELECT	tmpCus.CTSCustID
		,	tmpCus.Username
        ,	tmpCus.RegisterName
        ,	tmpCus.SubscriberID
    FROM Temp_Customer AS tmpCus
    ORDER BY tmpCus.CTSCustID DESC
	LIMIT ip_Skip, ip_Take ;
    
END$$
DELIMITER ;
