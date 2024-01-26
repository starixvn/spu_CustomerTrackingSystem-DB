/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Evolution_GetAttributes`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Evolution_GetAttributes`(
		IN ip_RawFingerPrintIDs		LONGTEXT
	,	IN ip_BrowserFamilyCode		VARCHAR(64)
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231124@Jonathan.Doan
	    Task : GetAttributes by RawFingerPrintIDs
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Evolution_GetAttributes('1,2,3', 'ABC');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputRawFingerPrintID;    
	CREATE TEMPORARY TABLE Temp_InputRawFingerPrintID(
		RawFingerPrintID		BIGINT UNSIGNED PRIMARY KEY
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputRawFingerPrintID (RawFingerPrintID) VALUES ('", REPLACE(ip_RawFingerPrintIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SELECT 	tmp.RawFingerPrintID
		,	bis.UserAgent
		,	bis.BrowserFamilyCode
		,	bis.OSName
		,	bis.BrowserName
		,	bis.BrowserVersion
		,	bis.Platform
		,	bis.Accept
		,	bis.Encoding
		,	bis.Headers
		,	fpa.LocalStorage
		,	fpa.DoNotTrack
		,	fpa.Cookies
		,	fpa.Canvas
		,	fpa.Fonts
		,	fpa.Vendor
		,	fpa.GLRenderer
		,	fpa.Plugins
		,	fpa.Languages
		,	fpa.Resolution
		,	fpa.Timezone
		,	fpa.ID
		,	bisa.ID
		,	bis.ID
	FROM Temp_InputRawFingerPrintID AS tmp
		INNER JOIN DCS_DataCenter.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = tmp.RawFingerPrintID
		INNER JOIN DCS_DataCenter.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintID = tmp.RawFingerPrintID
		INNER JOIN DCS_DataCenter.BrowserInstance AS bis ON bis.ID = bisa.BrowserInstanceID
 	WHERE bis.BrowserFamilyCode = ip_BrowserFamilyCode;
    
END$$

DELIMITER ;
