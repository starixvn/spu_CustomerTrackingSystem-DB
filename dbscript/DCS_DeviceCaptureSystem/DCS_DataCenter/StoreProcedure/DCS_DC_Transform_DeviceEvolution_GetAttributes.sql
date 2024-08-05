/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_DeviceEvolution_GetAttributes`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_DeviceEvolution_GetAttributes`(
    IN ip_listFingerprintID	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20240729@Jonathan.Doan
	    Task : Change Data Flow Ver. 6
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20240729@Jonathan.Doan: Created [RedmineID: #206403]
            
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_DeviceEvolution_GetAttributes('28,29');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_FP_FingerPrint;
    
	CREATE TEMPORARY TABLE Temp_FP_FingerPrint(
			ID		BIGINT UNSIGNED		PRIMARY KEY
    );
    
    
    SET @sql = CONCAT("INSERT IGNORE INTO Temp_FP_FingerPrint (ID) VALUES ('", REPLACE(ip_listFingerprintID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SELECT 	fp.ID AS FP_FingerPrintID
		,	fpe.Attribute->>'$.UserAgent' AS UserAgent
		,	fpe.Attribute->>'$.OSName' AS OSName
		,	fpe.Attribute->>'$.BrowserName' AS BrowserName
		,	fpe.Attribute->>'$.BrowserVersion' AS BrowserVersion
		,	fpe.Attribute->>'$.Platform' AS Platform
		,	fpe.Attribute->>'$.Accept' AS Accept
		,	fpe.Attribute->>'$.Encoding' AS Encoding
		,	fpe.Attribute->>'$.Headers' AS Headers
		,	fp.Attribute->>'$.LocalStorage' AS LocalStorage
		,	fp.Attribute->>'$.DoNotTrack' AS DoNotTrack
		,	fp.Attribute->>'$.CookiesEnabled' AS Cookies
		,	fp.Attribute->>'$.Canvas' AS Canvas
		,	fp.Attribute->>'$.Fonts' AS Fonts
		,	fp.Attribute->>'$.Vendor' AS Vendor
		,	fp.Attribute->>'$.WebGlBasics' AS GLRenderer
		,	fp.Attribute->>'$.Plugins' AS Plugins
		,	fp.Attribute->>'$.Languages' AS Languages
		,	fp.Attribute->>'$.ScreenResolution' AS Resolution
		,	fp.Attribute->>'$.Timezone' AS Timezone
	FROM Temp_FP_FingerPrint AS tmp
		INNER JOIN DCS_DataCenter.FP_FingerPrint AS fp ON fp.ID = tmp.ID
		LEFT JOIN DCS_DataCenter.FP_EvolvedMapping AS em ON em.FP_FingerprintID = tmp.ID
		LEFT JOIN DCS_DataCenter.FP_FingerPrintExtra AS fpe ON fpe.ID = em.FP_FingerPrintExtraID;
	
END$$

DELIMITER ;