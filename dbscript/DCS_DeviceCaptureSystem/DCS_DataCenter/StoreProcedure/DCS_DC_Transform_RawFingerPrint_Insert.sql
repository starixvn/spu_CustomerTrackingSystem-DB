/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawFingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawFingerPrint_Insert`(
		IN ip_RawFingerPrintJson	LONGTEXT
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
			- 20240621@Jonathan.Doan: Change data flow v5.1 [Redmine ID: #206403]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_RawFingerPrint_Insert('Temp_Transactions');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrintAttribute;
    
	CREATE TEMPORARY TABLE Temp_FingerPrintAttribute(
			ID				 						INT UNSIGNED AUTO_INCREMENT		NOT NULL
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
		,	UserAgent								VARCHAR(1000)	 	NULL
		,	IsNewRawFingerPrint						TINYINT		 		DEFAULT 1
		,	IsNewBrowserInstance					TINYINT		 		DEFAULT 1
		,	IsNewBrowserInstanceRawFingerPrint		TINYINT		 		DEFAULT 1
		,	IsNewFingerPrintAttribute				TINYINT		 		DEFAULT 1
        
        ,	PRIMARY KEY (ID)
    );
    
    
    INSERT IGNORE INTO Temp_FingerPrintAttribute(Attribute, FingerPrintCode, BrowserInstanceCode, BrowserFamilyCode, Accept, Encoding, Headers, OSName, BrowserName, BrowserVersion, Platform, UserAgent)
    SELECT	rt.Attribute
		,	rt.FingerPrintCode
		,	rt.BrowserInstanceCode
		,	rt.BrowserFamilyCode
		,	rt.Accept
		,	rt.Encoding
		,	rt.Headers
		,	rt.OSName
		,	rt.BrowserName
		,	rt.BrowserVersion
		,	rt.Platform
		,	rt.UserAgent
	FROM JSON_TABLE(
			ip_RawFingerPrintJson,
			 "$[*]" COLUMNS(
						Attribute			LONGTEXT	 	PATH "$.Attribute"
					,	FingerPrintCode		VARCHAR(64) 	PATH "$.FingerPrintCode"
					,	BrowserInstanceCode	VARCHAR(64) 	PATH "$.BrowserInstanceCode"
					,	BrowserFamilyCode	VARCHAR(64) 	PATH "$.BrowserFamilyCode"
					,	Accept				VARCHAR(200) 	PATH "$.Accept"
					,	Encoding			VARCHAR(200) 	PATH "$.Encoding"
					,	Headers				VARCHAR(700) 	PATH "$.Headers"
					,	OSName				VARCHAR(100) 	PATH "$.OSName"
					,	BrowserName			VARCHAR(100) 	PATH "$.BrowserName"
					,	BrowserVersion		VARCHAR(50) 	PATH "$.BrowserVersion"
					,	Platform			VARCHAR(45) 	PATH "$.Platform"
					,	UserAgent			VARCHAR(1000) 	PATH "$.UserAgent"
				)
		   ) AS  rt
	WHERE rt.FingerPrintCode <> '' 
		AND rt.FingerPrintCode <> 'null';
        
	ALTER TABLE Temp_FingerPrintAttribute
	ADD INDEX IX_Temp_FingerPrintAttribute_FingerPrintCode(FingerPrintCode),
	ADD INDEX IX_Temp_FingerPrintAttribute_BrowserInstanceCode(BrowserInstanceCode);
    
    UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN DCS_DataCenter.RawFingerPrint AS fp ON fp.FingerPrintCode = tmp.FingerPrintCode
    SET tmp.IsNewRawFingerPrint = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.RawFingerPrint(FingerPrintCode, CreatedDate)
	SELECT	DISTINCT 
			FingerPrintCode
        ,	lv_CurrentDate AS CreatedDate
	FROM Temp_FingerPrintAttribute
    WHERE IsNewRawFingerPrint = 1;
    
	UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN DCS_DataCenter.RawFingerPrint AS fp ON fp.FingerPrintCode = tmp.FingerPrintCode
	SET tmp.RawFingerPrintID = fp.ID;
    
    /******* Add INDEX RawFingerPrintID********************/
	ALTER TABLE Temp_FingerPrintAttribute
	ADD INDEX IX_Temp_FingerPrintAttribute_RawFingerPrintID(RawFingerPrintID);
    
    
    /******* BrowserInstance ********************/      
    UPDATE Temp_FingerPrintAttribute AS tmp
		INNER JOIN DCS_DataCenter.BrowserInstance AS bi ON bi.BrowserInstanceCode = tmp.BrowserInstanceCode
    SET tmp.IsNewBrowserInstance = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.BrowserInstance(BrowserInstanceCode, BrowserFamilyCode, UserAgent, OSName, BrowserName, BrowserVersion, Platform, Accept, Encoding, Headers, CreatedDate)
    SELECT	tmp.BrowserInstanceCode
		,	tmp.BrowserFamilyCode
		,	tmp.UserAgent
		,	tmp.OSName
		,	tmp.BrowserName
		,	tmp.BrowserVersion
		,	tmp.Platform
		,	tmp.Accept
		,	tmp.Encoding
		,	tmp.Headers
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_FingerPrintAttribute AS tmp
    WHERE tmp.BrowserInstanceCode != ''
		AND tmp.BrowserInstanceCode != 'null'
        AND tmp.IsNewBrowserInstance = 1;
    
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
    
    
    /*******FingerPrintAttribute********************/
    UPDATE Temp_FingerPrintAttribute AS tmp
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
	FROM Temp_FingerPrintAttribute AS tmp
    WHERE tmp.IsNewFingerPrintAttribute = 1;
    
END$$

DELIMITER ;
