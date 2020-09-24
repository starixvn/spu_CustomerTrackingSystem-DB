USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Subscriber_Update`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Subscriber_Update`(
		IN ip_SubscriberID		INT
	,	IN ip_SubscriberName	VARCHAR(50)
	,	IN ip_SubscriberType	TINYINT UNSIGNED
    ,	IN ip_SubscriberPrefix	VARCHAR(30)
    ,	IN ip_IsTest			BIT
	,	IN ip_SiteList			JSON
	,	IN ip_UserID 			INT

	, 	OUT op_ErrorMessage 	VARCHAR(2000)
)
sp: BEGIN
	/*
		Created:	20200911@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter
		Original: 
		Revisions:
            - [20200911@Roger.Le][138102]: Created
            - [20200924@Lex.Khuat][138102]: Support insert/update sub with multiple sites
            
		Param's Explanation:
			- ip_SubscriberID: 0 => Insert mode, <> 0 => Update mode, input siteID
			- ip_SubscriberType: 0 => Credit, 1 => Licensees
	*/
    
    DECLARE lv_CurrentTime		DATETIME	DEFAULT CURRENT_TIME();
    DECLARE lv_SubscriberID		INT			DEFAULT IFNULL(ip_SubscriberID, 0);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Sites;
    #============================================
    
	CREATE TEMPORARY TABLE Temp_Sites( 	 
			SiteID				INT
		, 	SiteName			VARCHAR(50)
		, 	RoleMapping 		TINYINT
        ,	CurrentSubID		INT	DEFAULT 0
        , 	INDEX			IX_Temp_Sites_SiteID (SiteID)
        ,	INDEX			IX_Temp_Sites_CurrentSubID (CurrentSubID)
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    #========= CHECK SUBSCRIBER NAME ALREADY EXISTS =========
    IF (EXISTS (SELECT 1
				FROM CTS_Admin.Subscriber
				WHERE SubscriberID <> lv_SubscriberID
                AND LOWER(SubscriberName) = LOWER(IFNULL(ip_SubscriberName, '')))) THEN
		SET op_ErrorMessage = 'Subscriber name already exists';
		LEAVE sp;
	END IF;
    
    #========= CHECK PREFIX ALREADY EXISTS =========
    IF (EXISTS (SELECT 1
				FROM CTS_Admin.Subscriber
                WHERE SubscriberID <> lv_SubscriberID
				AND LOWER(SubscriberPrefix) = LOWER(IFNULL(ip_SubscriberPrefix, '')))) THEN
		SET op_ErrorMessage = 'Subscriber prefix already exists';
		LEAVE sp;
	END IF;

    #========= GET DATA TO UPDATE =========
	INSERT INTO Temp_Sites (SiteID, SiteName, RoleMapping, CurrentSubID)
	SELECT	DISTINCT
			tmpTable.SiteID
		,	tmpTable.SiteName
        ,	tmpTable.RoleMapping
        ,	IFNULL(site.SubscriberID, 0)
	FROM JSON_TABLE(ip_SiteList,
		 "$[*]" COLUMNS(
		  SiteID				INT				PATH "$.SiteID" 
		, SiteName 				VARCHAR(50) 	PATH "$.SiteName"
		, RoleMapping			TINYINT 		PATH "$.RoleMapping" 
		 )) as tmpTable
	LEFT JOIN CTS_DataCenter.MappingSubscriberSite AS site
		ON tmpTable.SiteID = site.SiteID;
    
    #========= CHECK IF SITEID DUPLICATED IN PARAM =========
    IF (EXISTS (SELECT 1
				FROM Temp_Sites
                GROUP BY SiteID
                HAVING COUNT(*) > 1)) THEN
		SELECT LEFT(CONCAT('SiteID duplicating: ', GROUP_CONCAT(DISTINCT SiteID ORDER BY SiteID ASC SEPARATOR ', ')), 2000)
        INTO op_ErrorMessage
        FROM Temp_Sites
        GROUP BY SiteID
		HAVING COUNT(*) > 1;
		LEAVE sp;
	END IF;
    
    #========= CHECK IF SITEID ALREADY EXISTS IN DB =========
    IF (EXISTS (SELECT 1
				FROM Temp_Sites
				WHERE CurrentSubID <> lv_SubscriberID
				AND CurrentSubID <> 0)) THEN
        SELECT LEFT(CONCAT('SiteIDs already exists: ', GROUP_CONCAT(DISTINCT SiteID ORDER BY SiteID ASC SEPARATOR ', ')), 2000)
        INTO op_ErrorMessage
        FROM Temp_Sites
        WHERE CurrentSubID <> lv_SubscriberID
			AND CurrentSubID <> 0;
		LEAVE sp;
	END IF;

    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

	IF lv_SubscriberID <> 0 THEN
		#========= UPDATE SUBSCRIBER =========
		UPDATE CTS_Admin.Subscriber
        SET		SubscriberName = ip_SubscriberName
			,	SubscriberPrefix = ip_SubscriberPrefix
            ,	SubscriberType = ip_SubscriberType
            ,	IsTest = ip_IsTest
		WHERE SubscriberID = lv_SubscriberID;
        
    ELSE
		#========= INSERT SUBSCRIBER =========
		INSERT INTO CTS_Admin.Subscriber (SubscriberName, SubscriberPrefix, SubscriberType, SubscriberStatus, CreatedDate, CreatedBy, IsTest)
		SELECT	ip_SubscriberName
			,	ip_SubscriberPrefix
			,	ip_SubscriberType
			,	1
			,	lv_CurrentTime
			,	ip_UserID
			,	ip_IsTest;
		
		#========= GET NEW INSERTED SUBSCRIBER ID =========
		SELECT	SubscriberID
		INTO	lv_SubscriberID
		FROM CTS_Admin.Subscriber
		WHERE SubscriberName = ip_SubscriberName
		LIMIT 1;

	END IF;

	#========= INSERT NEW SITES =========
	INSERT INTO CTS_DataCenter.MappingSubscriberSite(SubscriberID, SubscriberName, RoleMapping, SubscriberType, SubscriberStatus, SubscriberGroupID, SiteID, SiteName)
	SELECT	lv_SubscriberID
		,	ip_SubscriberName
		,	tmp.RoleMapping
		,	ip_SubscriberType
		,	1
		,	CASE	WHEN ip_SubscriberType = 0 THEN 1 # Credit
					WHEN ip_SubscriberType = 1 THEN 2 # Licensee
					ELSE 2
			END AS SubscriberGroupID
		,	tmp.SiteID
		,	tmp.SiteName
	FROM Temp_Sites AS tmp
	WHERE tmp.CurrentSubID = 0;

	#========= UPDATE EXISTING SITES =========
    UPDATE CTS_DataCenter.MappingSubscriberSite AS site
    INNER JOIN Temp_Sites AS tmp
		ON site.SiteID = tmp.SiteID
		AND site.SubscriberID = tmp.CurrentSubID
    SET		site.SiteName = tmp.SiteName
		,	site.RoleMapping = tmp.RoleMapping
	WHERE tmp.CurrentSubID = lv_SubscriberID;

END$$

DELIMITER ;

