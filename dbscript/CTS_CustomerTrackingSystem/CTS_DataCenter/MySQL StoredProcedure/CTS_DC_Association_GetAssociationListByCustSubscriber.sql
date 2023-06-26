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
			CALL CTS_DC_Association_GetAssociationListByCustSubscriber(@ip_SubscriberID:=6,@ip_CTSCustID:=1379028,@ip_Skip:=0, @ip_Take:=10, @op_TotalItem); SELECT @op_TotalItem;
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE Temp_Association(
			CTSCustID		BIGINT UNSIGNED
        ,	DCSDeviceID		BIGINT
        ,	CreatedTime		DATETIME(4)
        
        ,	PRIMARY KEY PK_Temp_Association(CTSCustID, DCSDeviceID)
        ,	INDEX IX_Temp_Association_DCSDeviceID(DCSDeviceID)
    ); 
        
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID;
	CREATE TEMPORARY TABLE Temp_CTSCustID(
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer(
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
		,	UserName 		VARCHAR(50)
        ,	RegisterName	VARCHAR(50)
    );
    #Error Code: 1054. Unknown column 'tmpAa.CTSCustID' in 'on clause'

	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationAccount;
    CREATE TEMPORARY TABLE Temp_AssociationAccount(
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
		,	UserName 			VARCHAR(50)
        ,	RegisterName		VARCHAR(50)
        ,	DeviceInCommon		INT
        ,	OtherDeives			INT
        ,	AssociatedAccount	INT
        ,	IsFirstCust			BOOLEAN
        ,	MaxCreatedTime		DATETIME(4)
        
        ,	INDEX IX_Temp_AssociationAccount(IsFirstCust DESC, MaxCreatedTime DESC)
    );
    
    #======GET Cust Association LIST: ip_CTSCustID AND ASSOCIATED CUSTOMER=======================================    
    INSERT INTO Temp_Association(CTSCustID, DCSDeviceID, CreatedTime)
    SELECT	abd.CTSCustID
		,	abd.DCSDeviceID
        ,	abd.CreatedTime
    FROM CTS_DataCenter.AssociationByDevice AS abd
    WHERE abd.SubscriberID = ip_SubscriberID AND abd.CTSCustID = ip_CTSCustID;
    
    INSERT INTO Temp_CTSCustID(CTSCustID)
    SELECT DISTINCT abd.CTSCustID
    FROM CTS_DataCenter.AssociationByDevice AS abd
		INNER JOIN Temp_Association AS tmpAs ON abd.DCSDeviceID = tmpAs.DCSDeviceID AND abd.SubscriberID = ip_SubscriberID;    

	INSERT INTO Temp_Customer(CTSCustID, UserName, RegisterName)
    SELECT	cus.CTSCustID
        ,	cus.UserName
        ,	cus.RegisterName
	FROM Temp_CTSCustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
	DELETE tmpAs
    FROM Temp_Association AS tmpAs
		LEFT JOIN Temp_Customer AS tmpCs ON tmpAs.CTSCustID = tmpCs.CTSCustID
	WHERE tmpCs.CTSCustID IS NULL;
	
    #=====GET ASSOCIATION LIST OF ALL Association Cust===============================================================================

    INSERT IGNORE INTO Temp_Association(CTSCustID, DCSDeviceID, CreatedTime)
    SELECT	abd.CTSCustID
		,	abd.DCSDeviceID
        ,	abd.CreatedTime
    FROM CTS_DataCenter.AssociationByDevice AS abd
		INNER JOIN Temp_Customer AS tmpCus ON abd.SubscriberID = ip_SubscriberID AND abd.CTSCustID = tmpCus.CTSCustID AND abd.CTSCustID <> ip_CTSCustID;
	
	INSERT INTO Temp_AssociationAccount(CTSCustID, DeviceInCommon, OtherDeives, AssociatedAccount, IsFirstCust, MaxCreatedTime)
    SELECT	tmpAs.CTSCustID
		,	COUNT(DISTINCT CASE WHEN cus.CTSCustID > 0 THEN tmpAs.DCSDeviceID ELSE NULL END) AS DeviceInCommon
        ,	COUNT(DISTINCT tmpAs.DCSDeviceID) - COUNT(DISTINCT CASE WHEN cus.CTSCustID > 0 THEN tmpAs.DCSDeviceID ELSE NULL END) AS OtherDevices
		,	COUNT(DISTINCT cus.CTSCustID) AS AsscociatedAccount
        ,	MAX(CASE WHEN tmpAs.CTSCustID = ip_CTSCustID THEN 1 ELSE 0 END) AS IsFirstCust
        ,	MAX(tmpAs.CreatedTime) AS MaxCreatedTime
    FROM Temp_Association AS tmpAs
        LEFT JOIN CTS_DataCenter.AssociationByDevice AS abd ON abd.SubscriberID = ip_SubscriberID AND tmpAs.DCSDeviceID = abd.DCSDeviceID AND tmpAs.CTSCustID <> abd.CTSCustID
        LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON abd.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0
	GROUP BY tmpAs.CTSCustID;
    
    SET op_TotalItem = (SELECT COUNT(1) FROM Temp_AssociationAccount);

	SELECT	tmpAa.CTSCustID
		,	tmpCs.UserName
        ,	tmpCs.RegisterName
		,	tmpAa.DeviceInCommon
		,	tmpAa.OtherDeives
		,	tmpAa.AssociatedAccount
    FROM Temp_AssociationAccount AS tmpAa		
		INNER JOIN Temp_Customer AS tmpCs ON tmpAa.CTSCustID = tmpCs.CTSCustID
	ORDER BY IsFirstCust DESC, MaxCreatedTime DESC
    LIMIT ip_Skip, ip_Take;
	
END$$
DELIMITER ;
