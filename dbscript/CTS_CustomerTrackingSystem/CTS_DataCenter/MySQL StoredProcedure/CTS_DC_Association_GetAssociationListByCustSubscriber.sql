/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetAssociationListByCustSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetAssociationListByCustSubscriber`(
		IN ip_SubscriberID		INT
	,	IN ip_CTSCustID			BIGINT UNSIGNED
	,	IN ip_Skip				INT
    ,	IN ip_Take				INT
    ,	OUT	op_TotalItem		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230601@Casey.Huynh
		Task :		Get Association Account List
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230601@Casey.Huynh: Created [Redmine ID: 185787]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL CTS_DC_Association_GetAssociationListAccountByCustSubscriber(@ip_SubscriberID:=6,@ip_CTSCustID:=14417,@ip_Skip:=0, @ip_Take:=10, @op_TotalItem); SELECT @op_TotalItem;
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association01;
	CREATE TEMPORARY TABLE Temp_Association01(
			CTSCustID	BIGINT UNSIGNED
        ,	DCSDeviceID	BIGINT
        ,	CreatedTime	DATETIME(4)
        
        ,	PRIMARY KEY PK_Temp_Association01(CTSCustID, DCSDeviceID)
        ,	INDEX IX_Temp_Association01_DCSDeviceID(DCSDeviceID)
    ); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Association02;
	CREATE TEMPORARY TABLE Temp_Association02(
			CTSCustID	BIGINT UNSIGNED
        ,	DCSDeviceID	BIGINT
        ,	CreatedTime	DATETIME(4)
        
        ,	PRIMARY KEY PK_Temp_Association02(DCSDeviceID,CTSCustID)
        ,	INDEX IX_Temp_Association02_DCSDeviceID(CTSCustID)
    );     
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer(
		CTSCustID	BIGINT UNSIGNED
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationAccount;
    CREATE TEMPORARY TABLE Temp_AssociationAccount(
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
        ,	DeviceInCommon		INT
        ,	OtherDeives			INT
        ,	AssociatedAccount	INT
        ,	IsFirstCust			BOOLEAN
        ,	MaxCreatedTime		DATETIME(4)
        
        ,	INDEX IX_Temp_AssociationAccount(IsFirstCust DESC, MaxCreatedTime DESC)
    );
    #======GET ACCOUNT LIST: ip_CTSCustID AND ASSOCIATED CUSTOMER=======================================    
    INSERT INTO Temp_Association01(CTSCustID, DCSDeviceID, CreatedTime)
    SELECT	abd.CTSCustID
		,	abd.DCSDeviceID
        ,	abd.CreatedTime
    FROM CTS_DataCenter.AssociationByDevice AS abd
    WHERE abd.SubscriberID = ip_SubscriberID AND abd.CTSCustID = ip_CTSCustID;
    
    INSERT INTO Temp_Customer(CTSCustID)
    SELECT abd.CTSCustID
    FROM CTS_DataCenter.AssociationByDevice AS abd
		INNER JOIN Temp_Association01 AS tmpAs1 ON abd.DCSDeviceID = tmpAs1.DCSDeviceID AND abd.SubscriberID = ip_SubscriberID;
    
    #=====GET ASSOCIATION LIST===============================================================================
    INSERT INTO Temp_Association01(CTSCustID, DCSDeviceID, CreatedTime)
    SELECT	abd.CTSCustID
		,	abd.DCSDeviceID
        ,	abd.CreatedTime
    FROM CTS_DataCenter.AssociationByDevice AS abd
		INNER JOIN Temp_Customer AS tmpCus ON abd.SubscriberID = ip_SubscriberID AND abd.CTSCustID = tmpCus.CTSCustID AND abd.CTSCustID <> ip_CTSCustID;
    
    INSERT INTO Temp_Association02(CTSCustID, DCSDeviceID, CreatedTime)
    SELECT	tmpAs1.CTSCustID
		,	tmpAs1.DCSDeviceID
        ,	tmpAs1.CreatedTime
    FROM Temp_Association01 AS tmpAs1;
    
    INSERT INTO Temp_AssociationAccount(CTSCustID, DeviceInCommon, OtherDeives, AssociatedAccount, IsFirstCust, MaxCreatedTime)
    SELECT	tmpAs1.CTSCustID
		,	COUNT(DISTINCT(CASE WHEN tmpAs2.CTSCustID IS NOT NULL THEN tmpAs2.DCSDeviceID ELSE NULL END)) AS DeviceInCommon
        ,	COUNT(DISTINCT(CASE WHEN tmpAs2.CTSCustID IS NULL THEN tmpAs1.DCSDeviceID ELSE NULL END)) AS OtherDevices
		,	COUNT(DISTINCT(CASE WHEN tmpAs2.CTSCustID IS NOT NULL THEN tmpAs2.CTSCustID ELSE NULL END)) AS AsscociatedAccount
        ,	MAX(CASE WHEN tmpAs1.CTSCustID = ip_CTSCustID THEN 1 ELSE 0 END) AS IsFirstCust
        ,	MAX(tmpAs1.CreatedTime) AS MaxCreatedTime
    FROM Temp_Association01 AS tmpAs1
		LEFT JOIN Temp_Association02 AS tmpAs2 ON tmpAs1.DCSDeviceID = tmpAs2.DCSDeviceID AND tmpAs1.CTSCustID <> tmpAs2.CTSCustID
	GROUP BY tmpAs1.CTSCustID;
    
    SET op_TotalItem = (SELECT COUNT(1) FROM Temp_AssociationAccount);
    
	SELECT	tmpAa.CTSCustID
		,	cus.UserName
        ,	cus.RegisterName
		,	tmpAa.DeviceInCommon
		,	tmpAa.OtherDeives
		,	tmpAa.AssociatedAccount
    FROM Temp_AssociationAccount AS tmpAa
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpAa.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0
	ORDER BY IsFirstCust DESC, MaxCreatedTime DESC
    LIMIT ip_Skip, ip_Take;
	
END$$
DELIMITER ;
