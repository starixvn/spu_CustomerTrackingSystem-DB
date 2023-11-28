/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Evolution_GetAttributes_Jonathan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Evolution_GetAttributes_Jonathan`(
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
			CALL DCS_DC_Identity_Evolution_GetAttributes_Jonathan('1,2,3', '02a1916a67c78ee85e07eda8279617af');
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
		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = tmp.RawFingerPrintID
		INNER JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintID = tmp.RawFingerPrintID
		INNER JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.ID = bisa.BrowserInstanceID
 	WHERE bis.BrowserFamilyCode = ip_BrowserFamilyCode;
    
END$$

DELIMITER ;
