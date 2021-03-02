/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_AssociatedAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_AssociatedAccount`(
		IN ip_AccountStatusIDs	VARCHAR(100)
    , 	IN ip_SubscriberIDs 	TEXT
    ,	IN ip_AssociationStatus SMALLINT
    ,	IN ip_AssociationType	INT
    ,	IN ip_FromAssDate		DATETIME
    ,	IN ip_ToAssDate			DATETIME
    ,	IN ip_EvidenceIDs		VARCHAR(2000)
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
            - ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual
            - ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked
            - ip_AccountStatusIds: 1,11,2,3,4,12,13,14 - All,    1,11 - Open(1:Open, 11:Active),  2,3,4,12,13,14 - Closed (2:Disabled, 3:Closed, 4:Suspended, 12:Inactive, 13:View Only, 14:Suspended)
        Example:
			set @op_TotalItems = 0;
			call CTS_DataCenter.CTS_DC_RPT_AssociatedAccount('1,11','4414',0,0,'2021-01-28','2021-01-30',41,0,100, @op_TotalItems);
			 select @op_TotalItems;

	*/    
    SELECT DATE_ADD(ip_ToAssDate, INTERVAL 1 DAY)
    INTO ip_ToAssDate;    
    
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceID;
    CREATE TEMPORARY TABLE Temp_EvidenceID (
			EvidenceID		SMALLINT UNSIGNED
        , 	PRIMARY KEY  (EvidenceID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
    CREATE TEMPORARY TABLE Temp_CustEvidence (
			CTSCustID 		INT UNSIGNED
		,	UserName		VARCHAR(50)
		,	SubscriberID	INT
        ,	SubscriberName	VARCHAR(50)
        ,	CustStatusID	SMALLINT
        ,	EvidenceCode	VARCHAR(10)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Associations;
    CREATE TEMPORARY TABLE Temp_Associations (
			CTSCustID 		INT UNSIGNED
		,	AssociationDate	DATETIME
        , 	PRIMARY KEY  (CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Result;
    CREATE TEMPORARY TABLE Temp_Result (
			CTSCustID		BIGINT
		,	UserName		VARCHAR(50)
        ,	SubscriberID	INT
        ,	SubscriberName	VARCHAR(50)
        ,	AccountStatus	VARCHAR(200)
        ,	EvidenceCode	VARCHAR(10)
        , 	CategoryName	VARCHAR(50)
        ,	AssociationDate	DATETIME
	);

	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SubscriberID (SubscriberID) VALUES ('", REPLACE(ip_SubscriberIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustStatusID (CustStatusID) VALUES ('", REPLACE(ip_AccountStatusIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_EvidenceID (EvidenceID) VALUES ('", REPLACE(ip_EvidenceIDs, ",", "'),('"),"');");
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
        INNER JOIN Temp_EvidenceID tevi ON ce.EvidenceID = tevi.EvidenceID AND ce.Level = 0
		INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
        INNER JOIN CTS_Admin.Subscriber sub ON sub.SubscriberID = cus.SubscriberID
        INNER JOIN Temp_SubscriberID tsub ON cus.SubscriberID = tsub.SubscriberID
        INNER JOIN Temp_CustStatusID tstatus ON cus.CustStatusID = tstatus.CustStatusID;     
        
	IF ip_AssociationType = 0 OR ip_AssociationType = 1 THEN
		INSERT INTO Temp_Associations (CTSCustID, AssociationDate)
		SELECT tce.CTSCustID, ass.CreatedDate
		FROM Temp_CustEvidence tce
			INNER JOIN CTS_DataCenter.Association ass ON tce.CTSCustID = ass.FromCTSCustID OR tce.CTSCustID = ass.ToCTSCustID
            LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
		WHERE ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
			AND (ip_AssociationStatus = 0
				OR ip_AssociationStatus = 1 AND assRemove.FromCTSCustID IS NULL
                OR ip_AssociationStatus = 2 AND assRemove.FromCTSCustID IS NOT NULL)
		ON DUPLICATE KEY UPDATE AssociationDate = LEAST(Temp_Associations.AssociationDate, ass.CreatedDate);
	END IF;
    
    IF ip_AssociationType = 0 OR ip_AssociationType = 3 THEN
		INSERT INTO Temp_Associations (CTSCustID, AssociationDate)
		SELECT tce.CTSCustID, ass.CreatedDate
		FROM Temp_CustEvidence tce
			INNER JOIN CTS_DataCenter.AssociationByManual ass ON tce.CTSCustID = ass.FromCTSCustID OR tce.CTSCustID = ass.ToCTSCustID
            LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
		WHERE ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
			AND (ip_AssociationStatus = 0
				OR ip_AssociationStatus = 1 AND assRemove.FromCTSCustID IS NULL
                OR ip_AssociationStatus = 2 AND assRemove.FromCTSCustID IS NOT NULL)
		ON DUPLICATE KEY UPDATE AssociationDate = LEAST(Temp_Associations.AssociationDate, ass.CreatedDate);
	END IF;
	
    INSERT INTO Temp_Result (CTSCustID
		,	UserName
        ,	SubscriberID	
        ,	SubscriberName	
        ,	AccountStatus	
        ,	EvidenceCode	
        , 	CategoryName	
        ,	AssociationDate)
    SELECT DISTINCT tce.CTSCustID
		, tce.UserName
        , tce.SubscriberID
        , tce.SubscriberName
        , stl.ItemNameDisplay AS 'AccountStatus'
        , tce.EvidenceCode
        , cc.CategoryName
        , tass.AssociationDate
    FROM Temp_Associations tass
		INNER JOIN Temp_CustEvidence tce ON tass.CTSCustID = tce.CTSCustID
        INNER JOIN CTS_DataCenter.StaticList stl ON tce.CustStatusID = stl.ItemID AND stl.ListID = 1
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification custClass ON custClass.CTSCustID = tce.CTSCustID
        LEFT JOIN CTS_DataCenter.CustomerCategory cc ON cc.CategoryID = custClass.CategoryID AND custClass.SportGroupID = 200;
    
    SELECT *
    FROM Temp_Result
    ORDER BY AssociationDate DESC
    LIMIT ip_Take
    OFFSET ip_Skip;
	
    SELECT COUNT(*)
    INTO op_TotalItems
    FROM Temp_Result;	
	
END$$

DELIMITER ;