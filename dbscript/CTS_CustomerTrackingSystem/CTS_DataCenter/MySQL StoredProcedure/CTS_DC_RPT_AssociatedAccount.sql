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
			- 20210427@Aries.Nguyen: Enhance performance [Redmine ID: #152509] 
            
		Param's Explanation (filtered by):
            - ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual
            - ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked
            - ip_AccountStatusIds: 1,11,2,3,4,12,13,14 - All,    1,11 - Open(1:Open, 11:Active),  2,3,4,12,13,14 - Closed (2:Disabled, 3:Closed, 4:Suspended, 12:Inactive, 13:View Only, 14:Suspended)
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_RPT_AssociatedAccount('1,11','4414',0,0,'2021-01-28','2021-01-30',41,0,100, @op_TotalItems);

	*/    
    
    DECLARE lv_fromday 	INT;
    DECLARE lv_today 	INT;
    DECLARE lv_days 	JSON;

	IF (ip_SubscriberIDs IS NULL OR ip_SubscriberIDs = '' OR ip_SubscriberIDs = -1) 
		OR (ip_AssociationStatus IS NULL OR ip_AssociationStatus = '' OR ip_AssociationStatus = -1)
        OR (ip_EvidenceIDs IS NULL OR ip_EvidenceIDs = '' OR ip_EvidenceIDs = -1) THEN
		LEAVE sp;
    END IF;
    
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
		,	CustID			BIGINT
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE 		Temp_Device (
				DCSDeviceID 		BIGINT UNSIGNED PRIMARY KEY 
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
    
    SET lv_fromday = TO_DAYS(ip_FromAssDate);
	SET lv_today = TO_DAYS(ip_ToAssDate);
    
	WITH RECURSIVE CTE_Day (n) AS
	(
	  SELECT lv_fromday 
	  UNION ALL
	  SELECT  1  + n  FROM CTE_Day WHERE n < lv_today
	)
	SELECT JSON_ARRAYAGG(n)
	INTO lv_days
	FROM CTE_Day;
    
    UPDATE Temp_EvidenceID AS evID
	INNER JOIN CTS_DataCenter.Evidence evi ON evID.EvidenceID = evi.EvidenceID
	SET evID.EvidenceCode = evi.EvidenceCode;

    IF ip_AssociationType = 1 AND  ip_AssociationStatus = 0 THEN
		INSERT IGNORE INTO Temp_Device(DCSDeviceID)
		SELECT DCSDeviceID 
		FROM CTS_DataCenter.DeviceAssociationDay
		WHERE JSON_OVERLAPS(AssociationDay -> '$', lv_days); 
        
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE  EXISTS (SELECT 1 FROM AssociationByDevice AS dv 
							INNER JOIN Temp_Device AS tmp  ON tmp.DCSDeviceID = dv.DCSDeviceID 
					  WHERE dv.CTSCustID = ce.CTSCustID)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 1 AND  ip_AssociationStatus = 1 THEN
		INSERT IGNORE INTO Temp_Device(DCSDeviceID)
		SELECT DCSDeviceID 
		FROM CTS_DataCenter.DeviceAssociationDay
		WHERE JSON_OVERLAPS(AssociationDay -> '$', lv_days); 
        
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE  (SELECT 1 FROM AssociationByDevice AS dv 
					INNER JOIN Temp_Device AS tmp  ON dv.DCSDeviceID = tmp.DCSDeviceID
					INNER JOIN AssociationByDevice AS asDv  ON tmp.DCSDeviceID = asDv.DCSDeviceID
					LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = dv.CTSCustID AND assRemove.ToCTSCustID = asDv.CTSCustID
					LEFT JOIN CTS_DataCenter.AssociationRemove assRemove1 ON assRemove1.FromCTSCustID = asDv.CTSCustID AND assRemove1.ToCTSCustID = dv.CTSCustID
				WHERE dv.CTSCustID = ce.CTSCustID AND  dv.CTSCustID <> asDv.CTSCustID  AND	assRemove.FromCTSCustID IS NULL AND assRemove1.FromCTSCustID  IS NULL LIMIT 1) = 1
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 1 AND  ip_AssociationStatus = 2 THEN
		INSERT IGNORE INTO Temp_Device(DCSDeviceID)
		SELECT DCSDeviceID 
		FROM CTS_DataCenter.DeviceAssociationDay
		WHERE JSON_OVERLAPS(AssociationDay -> '$', lv_days); 
        
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
            INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = ce.CTSCustID
		WHERE (SELECT 1 FROM AssociationByDevice AS dv 
					INNER JOIN Temp_Device AS tmp  ON dv.DCSDeviceID = tmp.DCSDeviceID
					INNER JOIN AssociationByDevice AS asDv  ON tmp.DCSDeviceID = asDv.DCSDeviceID
					LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = dv.CTSCustID AND assRemove.ToCTSCustID = asDv.CTSCustID
					LEFT JOIN CTS_DataCenter.AssociationRemove assRemove1 ON assRemove1.FromCTSCustID = asDv.CTSCustID AND assRemove1.ToCTSCustID = dv.CTSCustID
				WHERE dv.CTSCustID = ce.CTSCustID AND  dv.CTSCustID <> asDv.CTSCustID  AND	assRemove.FromCTSCustID IS NOT NULL AND assRemove1.FromCTSCustID  IS NOT NULL LIMIT 1) = 1  
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
         
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode 
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
            INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON asRe.ToCTSCustID = ce.CTSCustID
		WHERE (SELECT 1 FROM AssociationByDevice AS dv 
					INNER JOIN Temp_Device AS tmp  ON dv.DCSDeviceID = tmp.DCSDeviceID
					INNER JOIN AssociationByDevice AS asDv  ON tmp.DCSDeviceID = asDv.DCSDeviceID
					LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = dv.CTSCustID AND assRemove.ToCTSCustID = asDv.CTSCustID
					LEFT JOIN CTS_DataCenter.AssociationRemove assRemove1 ON assRemove1.FromCTSCustID = asDv.CTSCustID AND assRemove1.ToCTSCustID = dv.CTSCustID
				WHERE dv.CTSCustID = ce.CTSCustID AND  dv.CTSCustID <> asDv.CTSCustID  AND	assRemove.FromCTSCustID IS NOT NULL AND assRemove1.FromCTSCustID  IS NOT NULL LIMIT 1) = 1  
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CASE WHEN Temp_CustEvidence.EvidenceCode LIKE CONCAT('%',evID.EvidenceCode,'%') THEN Temp_CustEvidence.EvidenceCode
																	   ELSE CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode) END;
    END IF;
    
	IF ip_AssociationType = 3 AND  ip_AssociationStatus = 0 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
						WHERE  ass.FromCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL 
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
						WHERE  ass.ToCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 3 AND  ip_AssociationStatus = 1 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
		WHERE (  
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
							LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
						WHERE  ass.FromCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
							AND	assRemove.FromCTSCustID IS NULL
						LIMIT 1)   IS NOT NULL
					OR
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
							LEFT JOIN CTS_DataCenter.AssociationRemove assRemove ON assRemove.FromCTSCustID = ass.FromCTSCustID AND assRemove.ToCTSCustID = ass.ToCTSCustID
						WHERE  ass.ToCTSCustID = ce.CTSCustID  
							AND	ass.CreatedDate BETWEEN ip_FromAssDate AND ip_ToAssDate
							AND	assRemove.FromCTSCustID IS NULL
						LIMIT 1)   IS NOT NULL 
			)
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode = CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode);
    END IF;
    
    IF ip_AssociationType = 3 AND  ip_AssociationStatus = 2 THEN
		INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
            INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON asRe.FromCTSCustID = ce.CTSCustID
		WHERE (   
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
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
         
        INSERT IGNORE INTO Temp_CustEvidence (CTSCustID,CustID,EvidenceID,UserName,SubscriberID,CustStatusID,EvidenceCode) 
		SELECT ce.CTSCustID
			,   cus.CustID
			,	ce.EvidenceID
			,	cus.UserName
			, 	cus.SubscriberID 
			,	cus.CustStatusID
			,	evID.EvidenceCode
		FROM  CTS_DataCenter.CustEvidence ce USE INDEX(IX_CustEvidence_Level_CTSCustID)
			INNER JOIN Temp_EvidenceID AS evID ON evID.EvidenceID = ce.EvidenceID AND  ce.LEVEL = 0
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON cus.CTSCustID = ce.CTSCustID
            INNER JOIN CTS_DataCenter.AssociationRemove AS asRe ON asRe.ToCTSCustID = ce.CTSCustID
		WHERE (   
					( 	SELECT ass.FromCTSCustID
						FROM CTS_DataCenter.AssociationByManual AS ass
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
		 ON DUPLICATE KEY UPDATE Temp_CustEvidence.EvidenceCode =CASE WHEN Temp_CustEvidence.EvidenceCode LIKE CONCAT('%',evID.EvidenceCode,'%') THEN Temp_CustEvidence.EvidenceCode
																	  ELSE CONCAT(Temp_CustEvidence.EvidenceCode, ', ', evID.EvidenceCode) END; 
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
        LEFT JOIN CTS_DataCenter.CTSCustomerClassification custClass ON custClass.CustID = ev.CustID
        LEFT JOIN CTS_DataCenter.CustomerCategory cc ON cc.CategoryID = custClass.CategoryID AND cc.ParentID IN (200,50)
        LEFT JOIN CTS_Admin.Subscriber sub ON sub.SubscriberID = ev.SubscriberID
	 WHERE ev.CustStatusID IN (SELECT CustStatusID FROM Temp_CustStatusID)
		   AND ev.SubscriberID IN (SELECT SubscriberID FROM Temp_SubscriberID)
	 ON DUPLICATE KEY UPDATE Temp_Result.CategoryName = CASE WHEN Temp_Result.CategoryName LIKE CONCAT('%',cc.CategoryName,'%') THEN Temp_Result.CategoryName
															 ELSE CONCAT(Temp_Result.CategoryName, ', ', cc.CategoryName)
														END;
    
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