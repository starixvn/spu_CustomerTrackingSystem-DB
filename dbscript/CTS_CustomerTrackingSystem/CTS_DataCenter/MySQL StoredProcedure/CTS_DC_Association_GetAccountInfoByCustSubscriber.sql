/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetAccountInfoByCustSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetAccountInfoByCustSubscriber`(
		IN ip_SubscriberID		INT
	,	IN ip_CTSCustID			BIGINT UNSIGNED       
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
			CALL CTS_DC_Association_GetAccountInfoByCustSubscriber(@ip_SubscriberID:=6,@ip_CTSCustID:=14417);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE Temp_Association(
			CTSCustID	BIGINT UNSIGNED
		,	AccountID	BIGINT UNSIGNED
        ,	DeviceID	BIGINT 
        ,	CreatedTime	DATETIME(4)
        
        ,	PRIMARY KEY PK_Temp_Association(DeviceID, AccountID)
        ,	INDEX IX_Temp_Association(CTSCustID)
    ); 
    
    #======GET ACCOUNT LIST: ip_CTSCustID AND ASSOCIATED CUSTOMER=======================================    
    INSERT INTO Temp_Association(CTSCustID, AccountID, DeviceID, CreatedTime)
    SELECT cda.CTSCustID, cda.AccountID, ass.DeviceID, ass.CreatedTime
	FROM CTS_DataCenter.CustDCSAccount AS cda 
        INNER JOIN DCS_DataCenter.Association AS ass ON cda.AccountID = ass.AccountID 
    WHERE cda.SubscriberID = ip_SubscriberID AND cda.CTSCustID = ip_CTSCustID;

    SELECT 	COUNT(DISTINCT tmpAs1.DeviceID) AssociatedDevices
		,	COUNT(DISTINCT cus.CTSCustID) AS AssociatedAccounts
        ,	MIN(tmpAs1.CreatedTime) AS FirstLogin
    FROM Temp_Association AS tmpAs1
		LEFT JOIN DCS_DataCenter.Association AS ass ON tmpAs1.DeviceID = ass.DeviceID AND tmpAs1.AccountID <> ass.AccountID AND ass.SubscriberID = ip_SubscriberID   
        LEFT JOIN CTS_DataCenter.CustDCSAccount AS cda ON cda.AccountID = ass.AccountID
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cda.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
END$$
DELIMITER ;
