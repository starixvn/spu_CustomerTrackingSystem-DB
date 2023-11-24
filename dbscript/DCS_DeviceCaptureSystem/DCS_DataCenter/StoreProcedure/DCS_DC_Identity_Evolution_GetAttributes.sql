/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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
		,	'' AS UserAgent
		,	'' AS BrowserFamilyCode
		,	'' AS OSName
		,	'' AS BrowserName
		,	'' AS BrowserVersion
		,	'' AS Platform
		,	'' AS Accept
		,	'' AS Encoding
		,	'' AS Headers
		,	-1 AS LocalStorage
		,	'' AS DoNotTrack
		,	-1 AS Cookies
		,	'' AS Canvas
		,	'' AS Fonts
		,	'' AS Vendor
		,	'' AS GLRenderer
		,	'' AS Plugins
		,	'' AS Languages
		,	'' AS Resolution
		,	'' AS Timezone
	FROM Temp_InputRawFingerPrintID AS tmp;
		-- INNER JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.ID = tmp.RawFingerPrintID
-- 		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
-- 		INNER JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintId = fp.Id
-- 		INNER JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = bisa.BrowserInstanceId
-- 	WHERE bis.BrowserFamilyCode = ip_BrowserFamilyCode;
    
END$$

DELIMITER ;
