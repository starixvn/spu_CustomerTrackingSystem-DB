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
    ,	IN ip_EvidenceIDs		VARCHAR(500)
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
			- CALL CTS_DataCenter.CTS_DC_RPT_AssociatedAccount('1,11','4414',0,0,'2021-01-28','2021-01-30',41,0,100, @op_TotalItems);

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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceID;
    CREATE TEMPORARY TABLE Temp_EvidenceID (
			EvidenceID		SMALLINT UNSIGNED
		,	Level 			INT DEFAULT 0
        ,	EvidenceCode 	VARCHAR(200)
        , 	PRIMARY KEY  (EvidenceID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
    CREATE TEMPORARY TABLE Temp_CustEvidence (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
		,	EvidenceID		INT
		,	UserName		VARCHAR(50)
		,	SubscriberID	INT
        ,	SubscriberName	VARCHAR(50)
        ,	CustStatusID	SMALLINT
        ,	EvidenceCode	VARCHAR(200)
        ,	INDEX IX_Temp_CustEvidence_CustStatusID (CustStatusID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Result;
    CREATE TEMPORARY TABLE Temp_Result (
			RowID 			INT AUTO_INCREMENT PRIMARY KEY
		,	CTSCustID		BIGINT UNIQUE 
		,	UserName		VARCHAR(50)
        ,	SubscriberID	INT
        ,	SubscriberName	VARCHAR(50)
        ,	AccountStatus	VARCHAR(50)
        ,	EvidenceCode	VARCHAR(200)
        , 	CategoryName	VARCHAR(300)
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
    
    UPDATE Temp_EvidenceID AS evID
	INNER JOIN CTS_DataCenter.Evidence evi ON evID.EvidenceID = evi.EvidenceID
	SET evID.EvidenceCode = evi.EvidenceCode;

    IF ip_AssociationType = 1 AND  ip_AssociationStatus = 0 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce
			INNER JOIN Temp_EvidenceID AS evID on evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association as ass
						WHERE  ass.FromCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association AS ass
						WHERE  ass.ToCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 1 AND  ip_AssociationStatus = 1 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce
			INNER JOIN Temp_EvidenceID AS evID on evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association as ass
							LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
						WHERE  ass.FromCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
							AND	assRemove.FromCTSCustID IS NULL
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association AS ass
							LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
						WHERE  ass.ToCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
							AND	assRemove.FromCTSCustID IS NULL
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 1 AND  ip_AssociationStatus = 2 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce
			INNER JOIN Temp_EvidenceID AS evID on evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
            INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association as ass
						WHERE  ass.FromCTSCustID = ce.CTSCustID   AND ass.ToCTSCustID = asRe.ToCTSCustID
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association AS ass
						WHERE  ass.ToCTSCustID = ce.CTSCustID   AND ass.FromCTSCustID = asRe.ToCTSCustID
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
				LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
	IF ip_AssociationType = 3 AND  ip_AssociationStatus = 0 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce
			INNER JOIN Temp_EvidenceID AS evID on evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual as ass
						WHERE  ass.FromCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association AS ass
						WHERE  ass.ToCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 3 AND  ip_AssociationStatus = 1 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce
			INNER JOIN Temp_EvidenceID AS evID on evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual as ass
							LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
						WHERE  ass.FromCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
							AND	assRemove.FromCTSCustID IS NULL
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.Association AS ass
							LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
						WHERE  ass.ToCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
							AND	assRemove.FromCTSCustID IS NULL
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 3 AND  ip_AssociationStatus = 2 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce
			INNER JOIN Temp_EvidenceID AS evID on evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
            INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual as ass
						WHERE  ass.FromCTSCustID = ce.CTSCustID   AND ass.ToCTSCustID = asRe.ToCTSCustID
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
						WHERE  ass.ToCTSCustID = ce.CTSCustID   AND ass.FromCTSCustID = asRe.ToCTSCustID
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    INSERT IGNORE INTO Temp_Result (CTSCustID, UserName, SubscriberID, SubscriberName, AccountStatus, EvidenceCode, CategoryName)
	SELECT ev.CTSCustID
		,	ev.UserName
		, 	ev.SubscriberID 
        ,	sub.SubscriberName
        ,	stl.ItemNameDisplay AS 'AccountStatus'
        ,	ev.EvidenceCode
        ,	cc.CategoryName
	FROM Temp_CustEvidence AS ev
		INNER JOIN CTS_DataCenter.StaticList stl ON ev.CustStatusID = stl.ItemID AND stl.ListID = 1
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification custClass ON custClass.CTSCustID = ev.CTSCustID
        LEFT JOIN CTS_DataCenter.CustomerCategory cc ON cc.CategoryID = custClass.CategoryID AND cc.ParentID IN (200,50)
        LEFT JOIN CTS_Admin.Subscriber sub ON sub.SubscriberID = ev.SubscriberID
	 WHERE ev.CustStatusID IN (SELECT CustStatusID FROM Temp_CustStatusID)
		   AND ev.SubscriberID IN (SELECT SubscriberID FROM Temp_SubscriberID)
	 ON DUPLICATE KEY UPDATE Temp_Result.CategoryName = CONCAT(Temp_Result.CategoryName, ', ', cc.CategoryName);
    
    SELECT CTSCustID
		,	UserName
        ,	SubscriberID	
        ,	SubscriberName	
        ,	AccountStatus	
        ,	EvidenceCode	
        , 	CategoryName	
    FROM Temp_Result
    ORDER BY RowID DESC
    LIMIT ip_Take
    OFFSET ip_Skip;
    
    SELECT IFNULL(MAX(rowID),0)
    INTO op_TotalItems
    FROM Temp_Result;	
	
END$$

DELIMITER ;