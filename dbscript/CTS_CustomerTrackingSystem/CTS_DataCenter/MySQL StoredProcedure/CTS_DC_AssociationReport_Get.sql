/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationReport_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationReport_Get`(
		IN ip_AccountStatusIDs	VARCHAR(100)
    , 	IN ip_SubscriberIDs 	TEXT
    ,	IN ip_AssociationStatus SMALLINT
    ,	IN ip_FromAssDate		DATETIME
    ,	IN ip_ToAssDate			DATETIME
    ,	IN ip_EvidenceID		SMALLINT
    ,	IN ip_Skip 				INT
    ,	IN ip_Take 				INT
    
    ,	OUT op_TotalItems		INT
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210226@Harvey.Nguyen
		Task:		Get association report 
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210226@Harvey.Nguyen: Created [Redmine ID: #150720]
            
		Param's Explanation (filtered by):
            - ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked
            - ip_AccountStatusIds: 1,11,2,3,4,12,13,14 - All,    1,11 - Open(1:Open, 11:Active),  2,3,4,12,13,14 - Closed (2:Disabled, 3:Closed, 4:Suspended, 12:Inactive, 13:View Only, 14:Suspended)
        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationReport_Get('1,11','4414',0,'2021-01-29','2021-01-30',41,0,100);
	*/    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SubscriberID;
    CREATE TEMPORARY TABLE Temp_SubscriberID (
			SubscriberID 		INT UNSIGNED
        , 	PRIMARY KEY  (SubscriberID)
	);   
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustStatusID;
    CREATE TEMPORARY TABLE Temp_CustStatusID (
			CustStatusID 		INT UNSIGNED
        , 	PRIMARY KEY  (CustStatusID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
    CREATE TEMPORARY TABLE Temp_CustEvidence (
			CTSCustID 		INT UNSIGNED
		,	UserName		VARCHAR(50)
		,	SubscriberID	INT
        ,	SubscriberName	VARCHAR(50)
        ,	CustStatusID	SMALLINT
        ,	EvidenceCode	VARCHAR(10)
        , 	PRIMARY KEY  (CTSCustID)
	);

	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SubscriberID (SubscriberID) VALUES ('", REPLACE(ip_SubscriberIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustStatusID (CustStatusID) VALUES ('", REPLACE(ip_AccountStatusIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    INSERT INTO Temp_CustEvidence (CTSCustID, UserName, SubscriberID, SubscriberName, CustStatusID, EvidenceCode)
    SELECT ce.CTSCustID
		, cus.UserName
		, cus.SubscriberID
        , sub.SubscriberName
        , cus.CustStatusID
        , evi.EvidenceCode
	FROM CustEvidence ce
		INNER JOIN CTS_DataCenter.Evidence evi ON ce.EvidenceID = evi.EvidenceID
		INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
        INNER JOIN CTS_Admin.Subscriber sub ON sub.SubscriberID = cus.SubscriberID
        INNER JOIN Temp_SubscriberID tsub ON cus.SubscriberID = tsub.SubscriberID
        INNER JOIN Temp_CustStatusID tstatus ON cus.CustStatusID = tstatus.CustStatusID
	WHERE ce.EvidenceID = ip_EvidenceID
		AND LEVEL = 0;
        
	SELECT DISTINCT tce.CTSCustID
		, tce.UserName
        , tce.SubscriberID
        , tce.SubscriberName
        , stl.ItemNameDisplay AS 'AccountStatus'
        , tce.EvidenceCode
        , cc.CategoryName
        , ass.CreatedDate
    FROM Temp_CustEvidence tce
		INNER JOIN CTS_DataCenter.Association ass ON tce.CTSCustID = ass.FromCTSCustID OR tce.CTSCustID = ass.ToCTSCustID
        INNER JOIN CTS_DataCenter.StaticList stl ON tce.CustStatusID = stl.ItemID AND stl.ListID = 1
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification custClass ON custClass.CTSCustID = tce.CTSCustID
        LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
        LEFT JOIN CTS_DataCenter.CustomerCategory cc ON cc.CategoryID = custClass.CategoryID AND custClass.SportGroupID = 200
	WHERE ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
		AND (ip_AssociationStatus = 0
				OR ip_AssociationStatus = 1 AND assRemove.FromCTSCustID IS NULL
                OR ip_AssociationStatus = 2 AND assRemove.FromCTSCustID IS NOT NULL)
    ORDER BY ass.CreatedDate DESC
    LIMIT ip_Take
    OFFSET ip_Skip;
	
    SELECT COUNT(1) 
    INTO op_TotalItems
	FROM Temp_CustEvidence;	
	
END$$

DELIMITER ;