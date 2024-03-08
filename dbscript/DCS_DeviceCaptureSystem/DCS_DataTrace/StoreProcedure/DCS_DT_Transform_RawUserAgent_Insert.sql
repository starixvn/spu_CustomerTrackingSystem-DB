/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Transform_RawUserAgent_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Transform_RawUserAgent_Insert`(
    IN ip_RawUserAgentIDs	LONGTEXT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20240308@Jonathan.Doan
	Task : Move RawUserAgent from DCS_DataCenter to DCS_DataTrace
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20240308@Jonathan.Doan: Created [Redmine ID: 199295]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Transform_RawUserAgent_Insert(10);
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputRawUserAgentID;
	DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
	DROP TEMPORARY TABLE IF EXISTS Temp_Browser;
	DROP TEMPORARY TABLE IF EXISTS Temp_OS;
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceType;
    
	CREATE TEMPORARY TABLE Temp_InputRawUserAgentID(
		RawUserAgentID		BIGINT UNSIGNED PRIMARY KEY
	);
    
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
			ID						BIGINT UNSIGNED PRIMARY KEY
		,	RawUserAgentCode		VARCHAR(100)
		,	RawUserAgent			VARCHAR(1000)
		,	BrowserID				BIGINT UNSIGNED DEFAULT NULL
		,	BrowserCode				VARCHAR(32)
		,	ClientType				VARCHAR(15)
		,	ClientName				VARCHAR(100)
		,	ClientVersion			VARCHAR(50)
		,	OSID					BIGINT UNSIGNED DEFAULT NULL
		,	OSCode					VARCHAR(32)
		,	OSName					VARCHAR(100)
		,	OSShortName				VARCHAR(50)
		,	OSVersion				VARCHAR(50)
		,	OSPlatform				VARCHAR(15)
		,	DeviceTypeID			BIGINT UNSIGNED DEFAULT NULL
		,	DeviceTypeCode			VARCHAR(32)
		,	Device					VARCHAR(50)
		,	Brand					VARCHAR(50)
		,	Model					VARCHAR(15)
		,	IsNewRecord				TINYINT	DEFAULT 1
	);
    
	CREATE TEMPORARY TABLE Temp_Browser(
			ID						BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	BrowserCode				VARCHAR(100)
		,	BrowserType				VARCHAR(15)
		,	BrowserName				VARCHAR(100)
		,	BrowserVersion			VARCHAR(50)
		,	IsNewRecord				TINYINT	DEFAULT 1
        
        , 	UNIQUE KEY `UX_Temp_Browser_BrowserCode` (`BrowserCode`)
	);
    
	CREATE TEMPORARY TABLE Temp_OS(
			ID						BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	OSCode					VARCHAR(100)
		,	OSName					VARCHAR(100)
		,	OSShortName				VARCHAR(50)
		,	OSVersion				VARCHAR(50)
		,	IsNewRecord				TINYINT	DEFAULT 1
        
        , 	UNIQUE KEY `UX_Temp_OS_OSCode` (`OSCode`)
	);
    
	CREATE TEMPORARY TABLE Temp_DeviceType(
			ID						BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	DeviceTypeCode			VARCHAR(100)
		,	DeviceType				VARCHAR(50)
		,	Brand					VARCHAR(50)
		,	Model					VARCHAR(15)
		,	IsNewRecord				TINYINT	DEFAULT 1
        
        , 	UNIQUE KEY `UX_Temp_DeviceType_DeviceTypeCode` (`DeviceTypeCode`)
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputRawUserAgentID (RawUserAgentID) VALUES ('", REPLACE(ip_RawUserAgentIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT IGNORE INTO Temp_RawUserAgent(ID, RawUserAgentCode, RawUserAgent, BrowserCode, ClientType, ClientName, ClientVersion, OSCode, OSName, OSShortName, OSVersion, DeviceTypeCode, Device, Brand, Model)
    SELECT 	ua.ID
		,	ua.RawUserAgentCode
		,	ua.RawUserAgent
		,	MD5(CONCAT(IFNULL(ua.ClientType, ''), IFNULL(ua.ClientName, ''), IFNULL(ua.ClientVersion, ''))) AS BrowserCode
		,	ua.ClientType
		,	ua.ClientName
		,	ua.ClientVersion
		,	MD5(CONCAT(IFNULL(ua.OSName, ''), IFNULL(ua.OSShortName, ''), IFNULL(ua.OSVersion, ''))) AS OSCode
		,	ua.OSName
		,	ua.OSShortName
		,	ua.OSVersion
		,	MD5(CONCAT(IFNULL(ua.Device, ''), IFNULL(ua.Brand, ''), IFNULL(ua.Model, ''))) AS DeviceTypeCode
		,	ua.Device
		,	ua.Brand
		,	ua.Model
    FROM Temp_InputRawUserAgentID AS tmp
 		INNER JOIN DCS_DataCenter.RawUserAgent AS ua ON ua.ID = tmp.RawUserAgentID
	WHERE NOT EXISTS (SELECT 1 FROM DCS_DataTrace.RawUserAgent as ua WHERE ua.ID = tmp.RawUserAgentID);
    
    /***== Insert Browser ==***/
    INSERT IGNORE INTO Temp_Browser(BrowserCode, BrowserType, BrowserName, BrowserVersion)
    SELECT	DISTINCT 
			BrowserCode
		,	ClientType
		,	ClientName
		,	ClientVersion
    FROM Temp_RawUserAgent;
	 
    UPDATE Temp_Browser AS tmp
		INNER JOIN DCS_DataTrace.Browser AS b ON b.BrowserCode = tmp.BrowserCode
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataTrace.Browser(BrowserCode, BrowserType, BrowserName, BrowserVersion, CreatedDate)
	SELECT	DISTINCT
			BrowserCode
		,	BrowserType
		,	BrowserName
		,	BrowserVersion
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_Browser
    WHERE IsNewRecord = 1;
    
	UPDATE Temp_RawUserAgent AS tmp
		INNER JOIN DCS_DataTrace.Browser AS b ON b.BrowserCode = tmp.BrowserCode
	SET tmp.BrowserID = b.ID;
    
    
    /***== Insert OS ==***/
    INSERT IGNORE INTO Temp_OS(OSCode, OSName, OSShortName, OSVersion)
    SELECT	DISTINCT
			OSCode
		,	OSName
		,	OSShortName
		,	OSVersion
    FROM Temp_RawUserAgent;
	
	ALTER TABLE Temp_OS
	ADD INDEX IX_Temp_OS_OSCode (OSCode);
	 
    UPDATE Temp_OS AS tmp
		INNER JOIN DCS_DataTrace.OS AS os ON os.OSCode = tmp.OSCode
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataTrace.OS(OSCode, OSName, OSShortName, OSVersion, CreatedDate)
	SELECT	DISTINCT
			OSCode
		,	OSName
		,	OSShortName
		,	OSVersion
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_OS
    WHERE IsNewRecord = 1;
    
	UPDATE Temp_RawUserAgent AS tmp
		INNER JOIN DCS_DataTrace.OS AS os ON os.OSCode = tmp.OSCode
	SET tmp.OSID = os.ID;
    
    
    /***== Insert DeviceType ==***/
    INSERT IGNORE INTO Temp_DeviceType(DeviceTypeCode, DeviceType, Brand, Model)
    SELECT	DISTINCT
			DeviceTypeCode
		,	Device
		,	Brand
		,	Model
    FROM Temp_RawUserAgent;
	
	ALTER TABLE Temp_DeviceType
	ADD INDEX IX_Temp_DeviceType_DeviceTypeCode (DeviceTypeCode);
	 
    UPDATE Temp_DeviceType AS tmp
		INNER JOIN DCS_DataTrace.DeviceType AS dt ON dt.DeviceTypeCode = tmp.DeviceTypeCode
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataTrace.DeviceType(DeviceTypeCode, DeviceType, Brand, Model, CreatedDate)
	SELECT	DISTINCT
			DeviceTypeCode
		,	DeviceType
		,	Brand
		,	Model
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_DeviceType
    WHERE IsNewRecord = 1;
    
	UPDATE Temp_RawUserAgent AS tmp
		INNER JOIN DCS_DataTrace.DeviceType AS dt ON dt.DeviceTypeCode = tmp.DeviceTypeCode
	SET tmp.DeviceTypeID = dt.ID;
    
    
    /***== Insert RawUserAgent ==***/
    INSERT IGNORE INTO DCS_DataTrace.RawUserAgent(ID, UserAgent, BrowserID, OSID, DeviceTypeID, CreatedDate)
    SELECT 	ID
		,	RawUserAgent AS UserAgent
		,	BrowserID
		,	OSID
		,	DeviceTypeID
		,	lv_CreatedDate AS CreatedDate
    FROM Temp_RawUserAgent;
    
END$$
DELIMITER ;
