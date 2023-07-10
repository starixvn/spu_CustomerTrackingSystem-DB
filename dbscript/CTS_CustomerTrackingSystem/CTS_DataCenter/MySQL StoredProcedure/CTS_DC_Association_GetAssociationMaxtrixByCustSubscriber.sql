/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetAssociationMaxtrixByCustSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetAssociationMaxtrixByCustSubscriber`(
		IN ip_SubscriberID	INT
	,	IN ip_CTSCustID		BIGINT UNSIGNED
	,	IN ip_NoOfCustomer	INT
    ,	IN ip_NoOfDevice	INT
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
				CALL CTS_DC_Association_GetAssociationMaxtrixByCustSubscriber(@ip_SubscriberID:=6,@ip_CTSCustID:=1379028,@ip_NoOfCustomer:=15);
   
	*/
        
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
	CREATE TEMPORARY TABLE Temp_Association(
			AccountID		BIGINT UNSIGNED
		,	DeviceID		BIGINT UNSIGNED
        ,	CTSCustID		BIGINT UNSIGNED
        ,	CreatedTime		DATETIME(4)
        
        ,	PRIMARY KEY PK_Temp_Association(AccountID, DeviceID)
        ,	INDEX IX_Temp_Association_DeviceID(DeviceID)
        ,	INDEX IX_Temp_Association_CTSCustID(CTSCustID)
    ); 
        
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountID;
	CREATE TEMPORARY TABLE Temp_AccountID(
			AccountID		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedAccount;
	CREATE TEMPORARY TABLE Temp_AssociatedAccount(
			AccountID		BIGINT UNSIGNED PRIMARY KEY
		,	CTSCustID		BIGINT UNSIGNED
		,	UserName 		VARCHAR(50)
        ,	RegisterName	VARCHAR(50)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LimitCustomer;
	CREATE TEMPORARY TABLE Temp_LimitCustomer(
			CTSCustID BIGINT UNSIGNED PRIMARY KEY
		,	IsFirstCust BOOLEAN
        ,	MaxCreatedTime DATETIME(4)
	);        
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LimitDevice;
	CREATE TEMPORARY TABLE Temp_LimitDevice(
			DeviceID BIGINT UNSIGNED PRIMARY KEY
		,	MaxCreatedTime DATETIME(4)
	);   
    
    #======GET Cust Association LIST: ip_CTSCustID AND ASSOCIATED CUSTOMER=======================================    
    INSERT INTO Temp_Association(AccountID, DeviceID, CTSCustID,  CreatedTime)
    SELECT	ass.AccountID
		,	ass.DeviceID
		,	cda.CTSCustID
        ,	ass.CreatedTime
    FROM CTS_DataCenter.CustDCSAccount AS cda
		INNER JOIN DCS_DataCenter.Association AS ass ON cda.AccountID = ass.AccountID
    WHERE cda.SubscriberID = ip_SubscriberID AND cda.CTSCustID = ip_CTSCustID;
    
    INSERT INTO Temp_AccountID(AccountID)
    SELECT DISTINCT ass.AccountID
    FROM DCS_DataCenter.Association AS ass
		INNER JOIN Temp_Association AS tmpAs ON ass.DeviceID = tmpAs.DeviceID AND ass.SubscriberID = ip_SubscriberID;    

	INSERT INTO Temp_AssociatedAccount(AccountID, CTSCustID, UserName, RegisterName)
    SELECT	tmp.AccountID
		,	cus.CTSCustID
        ,	cus.UserName
        ,	cus.RegisterName
	FROM Temp_AccountID AS tmp
		INNER JOIN CTS_DataCenter.CustDCSAccount AS cda ON tmp.AccountID = cda.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cda.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
	DELETE tmpAs
    FROM Temp_Association AS tmpAs
		LEFT JOIN Temp_AssociatedAccount AS tmpCs ON tmpAs.AccountID = tmpCs.AccountID
	WHERE tmpCs.CTSCustID IS NULL;

    #=====GET ASSOCIATION LIST OF ALL Association Cust===============================================================================

    INSERT IGNORE INTO Temp_Association(AccountID, DeviceID, CTSCustID,  CreatedTime)
    SELECT	ass.AccountID
		,	ass.DeviceID
        ,	tmpAcc.CTSCustID
        ,	ass.CreatedTime
    FROM DCS_DataCenter.Association AS ass
		INNER JOIN Temp_AssociatedAccount AS tmpAcc ON ass.SubscriberID = ip_SubscriberID AND ass.AccountID = tmpAcc.AccountID AND tmpAcc.CTSCustID <> ip_CTSCustID;
    
    INSERT INTO Temp_LimitCustomer(CTSCustID, IsFirstCust,MaxCreatedTime)
    SELECT	tmpAs.CTSCustID
		,	(CASE WHEN tmpAs.CTSCustID = ip_CTSCustID THEN 1 ELSE 0 END) AS IsFirstCust
        , 	MAX(tmpAs.CreatedTime) AS MaxCreatedTime
    FROM Temp_Association AS tmpAs
    GROUP BY tmpAs.CTSCustID
    ORDER BY IsFirstCust DESC, MaxCreatedTime DESC
    LIMIT ip_NoOfCustomer;
       
	INSERT INTO Temp_LimitDevice(DeviceID, MaxCreatedTime)
    SELECT	tmpAs.DeviceID
		, 	MAX(tmpAs.CreatedTime) AS MaxCreatedTime
    FROM Temp_Association AS tmpAs
    GROUP BY tmpAs.DeviceID
    ORDER BY MaxCreatedTime DESC
    LIMIT ip_NoOfDevice;
    
	SELECT	 tmpAc.CTSCustID
		,	tmpCs.UserName
        ,	tmpCs.RegisterName
		,	dv.DeviceID
		,	dv.FirstDeviceCode
		,	(CASE WHEN dv.DeviceID > 0 THEN tmpAc.CreatedTime ELSE NULL END) AS CreatedTime
    FROM Temp_Association AS tmpAc
		INNER JOIN Temp_LimitCustomer AS tmpCus ON tmpCus.CTSCustID = tmpAc.CTSCustID
        LEFT JOIN Temp_LimitDevice AS tmpDv ON tmpDv.DeviceID = tmpAc.DeviceID
        INNER JOIN Temp_AssociatedAccount AS tmpCs ON tmpCs.CTSCustID = tmpAc.CTSCustID
        LEFT JOIN DCS_DataCenter.Device AS dv ON dv.DeviceID = tmpDv.DeviceID
	ORDER BY tmpCus.IsFirstCust DESC, tmpCus.MaxCreatedTime DESC;    
    
END$$
DELIMITER ;
