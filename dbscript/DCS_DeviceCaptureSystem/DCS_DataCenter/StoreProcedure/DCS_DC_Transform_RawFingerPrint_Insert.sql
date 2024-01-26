/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawFingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawFingerPrint_Insert`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231108@Jonathan.Doan
		Task : Insert into RawFingerPrint, FingerprintAttribute, BrowserInstance
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231108@Jonathan.Doan: Created [Redmine ID: #196570]
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_RawFingerPrint_Insert('Temp_Transactions');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_InputData;
	DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrintAttribute;
	DROP TEMPORARY TABLE IF EXISTS Temp_GroupFingerPrintCode;
    
	CREATE TEMPORARY TABLE Temp_InputData(
			TmpID			 			INT NOT NULL 
		,	FingerprintAttribute		JSON NULL
        
        ,	PRIMARY KEY (TmpID)
    );
    
	CREATE TEMPORARY TABLE Temp_FingerPrintAttribute(
			TmpID 									INT 				NOT NULL 
		,	RawFingerPrintID						BIGINT UNSIGNED 	NULL
		,	BrowserInstanceID						BIGINT UNSIGNED 	NULL
		,	Attribute								LONGTEXT	 		NULL
		,	FingerPrintCode							VARCHAR(64) 		NULL
		,	BrowserInstanceCode						VARCHAR(64) 		NULL
		,	BrowserFamilyCode						VARCHAR(64) 		NULL
		,	Accept									VARCHAR(200)	 	NULL
		,	Encoding								VARCHAR(200)	 	NULL
		,	Headers									VARCHAR(700)	 	NULL
		,	OSName									VARCHAR(100)	 	NULL
		,	BrowserName								VARCHAR(100)	 	NULL
		,	BrowserVersion							VARCHAR(50)	 		NULL
		,	Platform								VARCHAR(45)	 		NULL
		,	UserAgent								LONGTEXT	 		NULL
		,	IsNewBrowserInstance					TINYINT		 		DEFAULT 1
		,	IsNewBrowserInstanceRawFingerPrint		TINYINT		 		DEFAULT 1
        
        ,	PRIMARY KEY (TmpID)
    );
    
	CREATE TEMPORARY TABLE Temp_GroupFingerPrintCode(
			ID										INT UNSIGNED 		NOT NULL 	AUTO_INCREMENT
		,	RawFingerPrintID						BIGINT UNSIGNED 	NULL
		,	FingerPrintCode							VARCHAR(64) 		NULL
		,	Attribute								LONGTEXT	 		NULL
		,	IsNewRawFingerPrint						TINYINT		 		DEFAULT 1
		,	IsNewFingerPrintAttribute				TINYINT		 		DEFAULT 1
        
        ,	PRIMARY KEY (ID)
    );
    
    /*******InputData********************/
	SET @sql = CONCAT('INSERT IGNORE INTO Temp_InputData(TmpID, FingerprintAttribute) 
						SELECT DISTINCT ID, FingerprintAttribute
                        FROM ', ip_TableName, 
					' WHERE IFNULL(FingerprintAttribute,'''') != '''' ');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    /*******FingerPrintAttribute********************/
    INSERT INTO Temp_FingerPrintAttribute(TmpID, Attribute, FingerPrintCode, BrowserInstanceCode, BrowserFamilyCode, Accept, Encoding, Headers, OSName, BrowserName, BrowserVersion, Platform, UserAgent)
    SELECT 	TmpID
		,	FingerprintAttribute->>'$.Attribute'
		,	FingerprintAttribute->>'$.FingerPrintCode'
		,	FingerprintAttribute->>'$.BrowserInstanceCode'
		,	FingerprintAttribute->>'$.BrowserFamilyCode'
		,	FingerprintAttribute->>'$.Accept'
		,	FingerprintAttribute->>'$.Encoding'
		,	FingerprintAttribute->>'$.Headers'
		,	FingerprintAttribute->>'$.OSName'
		,	FingerprintAttribute->>'$.BrowserName'
		,	FingerprintAttribute->>'$.BrowserVersion'
		,	FingerprintAttribute->>'$.Platform'
		,	FingerprintAttribute->>'$.UserAgent'
    FROM Temp_InputData;
    
    DELETE FROM Temp_FingerPrintAttribute
    WHERE FingerPrintCode = '' 
		OR FingerPrintCode = 'null';
	
    /******* Add INDEX Temp_FingerPrintAttribute********************/
	ALTER TABLE Temp_FingerPrintAttribute
	ADD INDEX IX_Temp_FingerPrintAttribute_FingerPrintCode(FingerPrintCode),
	ADD INDEX IX_Temp_FingerPrintAttribute_BrowserInstanceCode(BrowserInstanceCode);
    
    /*******Group by FingerPrintCode*****/
    INSERT INTO Temp_GroupFingerPrintCode(FingerPrintCode, Attribute)
    SELECT 	FingerPrintCode
		,	MIN(Attribute) AS Attribute
    FROM Temp_FingerPrintAttribute
    GROUP BY FingerPrintCode;
	
    /******* Add INDEX Temp_GroupFingerPrintCode ********************/
	ALTER TABLE Temp_GroupFingerPrintCode
	ADD INDEX IX_Temp_GroupFingerPrintCode_FingerPrintCode(FingerPrintCode);
    
    /*******RawFingerPrint********************/    
    UPDATE Temp_GroupFingerPrintCode AS tmp
		INNER JOIN DCS_DataCenter.RawFingerPrint AS fp ON fp.FingerPrintCode = tmp.FingerPrintCode
    SET tmp.IsNewRawFingerPrint = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.RawFingerPrint(FingerPrintCode, CreatedDate)
	SELECT	DISTINCT 
			FingerPrintCode
        ,	lv_CurrentDate AS CreatedDate
	FROM Temp_GroupFingerPrintCode
    WHERE IsNewRawFingerPrint = 1;
    
	UPDATE Temp_GroupFingerPrintCode AS tmp
		INNER JOIN DCS_DataCenter.RawFingerPrint AS fp ON fp.FingerPrintCode = tmp.FingerPrintCode
	SET tmp.RawFingerPrintID = fp.ID;
    
	UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN Temp_GroupFingerPrintCode AS tmpG ON tmpG.FingerPrintCode = tmp.FingerPrintCode
	SET tmp.RawFingerPrintID = tmpG.RawFingerPrintID;
    
	
    /******* Add INDEX RawFingerPrintID********************/
	ALTER TABLE Temp_GroupFingerPrintCode
	ADD INDEX IX_Temp_GroupFingerPrintCode_RawFingerPrintID(RawFingerPrintID);
    
	ALTER TABLE Temp_FingerPrintAttribute
	ADD INDEX IX_Temp_FingerPrintAttribute_RawFingerPrintID(RawFingerPrintID);
    
    /*******FingerPrintAttribute********************/
    UPDATE Temp_GroupFingerPrintCode AS tmp
		INNER JOIN DCS_DataCenter.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintID = tmp.RawFingerPrintID
    SET tmp.IsNewFingerPrintAttribute = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.FingerPrintAttribute(RawFingerPrintID, DoNotTrack, GLRenderer, Audio, Canvas, ColorDepth, ColorGamut, Contrast, Cookies, CpuClass, DeviceMemory, DomBlockers, FontPreferencePrint, Fonts, ForcedColors, HardwareConcurrency, HDR, IndexedDB, InvertedColors, Languages, LocalStorage, Math, Monochrome, OpenDatabase, OsCpu, Platform, Plugins, ReducedMotion, Resolution, SessionStorage, Timezone, TouchSupport, Vendor, VendorFlavors, WebglPrint, ApplePay, Architecture, PDFViewerEnabled, PrivateClickMeasurement, ReducedTransparency, WebGlBasics, webGlExtensions)
    SELECT	tmp.RawFingerPrintID
		,	tmp.Attribute->>'$.doNotTrack' AS DoNotTrack
		,	tmp.Attribute->>'$.webglRenderer' AS GLRenderer
		,	tmp.Attribute->>'$.audio' AS Audio
		,	tmp.Attribute->>'$.canvasPrint' AS Canvas
		,	tmp.Attribute->>'$.colorDepth' AS ColorDepth
		,	tmp.Attribute->>'$.colorGamut' AS ColorGamut
		,	tmp.Attribute->>'$.contrast' AS Contrast
		,	CASE tmp.Attribute->>'$.cookiesEnabled'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS Cookies
		,	tmp.Attribute->>'$.cpuClass' AS CpuClass
		,	CASE tmp.Attribute->>'$.deviceMemory'
					WHEN 'undefined' THEN -1
                    ELSE tmp.Attribute->>'$.deviceMemory' END AS DeviceMemory
		,	tmp.Attribute->>'$.domBlockers' AS DomBlockers
		,	tmp.Attribute->>'$.fontPreferencePrint' AS FontPreferencePrint
		,	tmp.Attribute->>'$.fonts' AS Fonts
		,	CASE tmp.Attribute->>'$.forcedColors'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS ForcedColors
		,	CASE tmp.Attribute->>'$.hardwareConcurrency'
					WHEN 'undefined' THEN -1
                    ELSE tmp.Attribute->>'$.hardwareConcurrency' END AS HardwareConcurrency
		,	CASE tmp.Attribute->>'$.hdr'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS HDR
		,	CASE tmp.Attribute->>'$.indexedDB'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS IndexedDB
		,	CASE tmp.Attribute->>'$.invertedColors'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS InvertedColors
		,	tmp.Attribute->>'$.languagesPrint' AS Languages
		,	CASE tmp.Attribute->>'$.localStorage'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS LocalStorage
		,	tmp.Attribute->>'$.math' AS Math
		,	CASE tmp.Attribute->>'$.monochrome'
					WHEN 'undefined' THEN -1
                    ELSE tmp.Attribute->>'$.monochrome' END AS Monochrome
		,	CASE tmp.Attribute->>'$.openDatabase'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS OpenDatabase
		,	tmp.Attribute->>'$.osCpu' AS OSCpu
		,	tmp.Attribute->>'$.platform' AS Platform
		,	tmp.Attribute->>'$.plugins' AS Plugins
		,	CASE tmp.Attribute->>'$.reducedMotion'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS ReducedMotion
		,	tmp.Attribute->>'$.screenPrint' AS Resolution
		,	CASE tmp.Attribute->>'$.sessionStorage'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS sessionStorage
		,	tmp.Attribute->>'$.timezone' AS Timezone
		,	tmp.Attribute->>'$.touchSupport' AS TouchSupport
		,	tmp.Attribute->>'$.vendor' AS Vendor
		,	tmp.Attribute->>'$.vendorFlavors' AS VendorFlavors
		,	tmp.Attribute->>'$.webglPrint' AS WebglPrint
		,	tmp.Attribute->>'$.applePay' AS ApplePay
		,	tmp.Attribute->>'$.architecture' AS Architecture
		,	tmp.Attribute->>'$.pdfViewerEnabled' AS PDFViewerEnabled
		,	CASE tmp.Attribute->>'$.privateClickMeasurement'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS PrivateClickMeasurement
		,	CASE tmp.Attribute->>'$.reducedTransparency'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS ReducedTransparency
		,	tmp.Attribute->>'$.webGlBasics' AS WebGlBasics
		,	tmp.Attribute->>'$.webGlExtensions' AS WebGlExtensions
	FROM Temp_GroupFingerPrintCode AS tmp
    WHERE tmp.IsNewFingerPrintAttribute = 1;
    
    /******* BrowserInstance ********************/      
    UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN DCS_DataCenter.BrowserInstance AS bi ON bi.BrowserInstanceCode = tmp.BrowserInstanceCode
    SET tmp.IsNewBrowserInstance = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.BrowserInstance(BrowserInstanceCode, BrowserFamilyCode, UserAgent, OSName, BrowserName, BrowserVersion, Platform, Accept, Encoding, Headers, CreatedDate)
    SELECT	tmp.BrowserInstanceCode
		,	MIN(tmp.BrowserFamilyCode) AS BrowserFamilyCode
		,	MIN(tmp.UserAgent) AS UserAgent
		,	MIN(tmp.OSName) AS OSName
		,	MIN(tmp.BrowserName) AS BrowserName
		,	MIN(tmp.BrowserVersion) AS BrowserVersion
		,	MIN(tmp.Platform) AS Platform
		,	MIN(tmp.Accept) AS Accept
		,	MIN(tmp.Encoding) AS Encoding
		,	MIN(tmp.Headers) AS Headers
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_FingerPrintAttribute AS tmp
    WHERE tmp.BrowserInstanceCode != ''
		AND tmp.BrowserInstanceCode != 'null'
        AND tmp.IsNewBrowserInstance = 1
	GROUP BY tmp.BrowserInstanceCode;
    
	UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN DCS_DataCenter.BrowserInstance AS bi ON bi.BrowserInstanceCode = tmp.BrowserInstanceCode
	SET tmp.BrowserInstanceID = bi.ID;
	
    /******* Add INDEX BrowserInstanceID********************/
	ALTER TABLE Temp_FingerPrintAttribute
	ADD INDEX IX_Temp_FingerPrintAttribute_BrowserInstanceID(BrowserInstanceID);
    
    /******* BrowserInstanceRawFingerPrint ********************/
    UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN DCS_DataCenter.BrowserInstanceRawFingerPrint AS bifp ON bifp.RawFingerPrintID = tmp.RawFingerPrintID 
																		AND bifp.BrowserInstanceID = tmp.BrowserInstanceID
    SET tmp.IsNewBrowserInstanceRawFingerPrint = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.BrowserInstanceRawFingerPrint(RawFingerPrintID, BrowserInstanceID)
    SELECT 	DISTINCT
			RawFingerPrintID
		,	BrowserInstanceID
    FROM Temp_FingerPrintAttribute
    WHERE IsNewBrowserInstanceRawFingerPrint = 1;
    
    /* Update RawFingerPrintID */
	SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
						INNER JOIN Temp_FingerPrintAttribute AS tmp_fpa ON tmp_fpa.TmpID = tmp.ID
						SET tmp.RawFingerPrintID = tmp_fpa.RawFingerPrintID,
							tmp.BrowserInstanceID = tmp_fpa.BrowserInstanceID');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;
