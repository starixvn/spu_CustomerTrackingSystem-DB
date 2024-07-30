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
			CALL DCS_DC_Transform_DeviceEvolution_GetAttributes('1,2,3');
	*/
    
    
    SELECT 	1 AS FP_FingerPrintID
		,	'sample' AS FP_UserAgent
		,	'sample' AS BrowserFamilyCode
		,	'sample' AS OSName
		,	'sample' AS BrowserName
		,	'sample' AS BrowserVersion
		,	'sample' AS Platform
		,	'sample' AS Accept
		,	'sample' AS Encoding
		,	'sample' AS Headers
		,	0 AS LocalStorage
		,	'sample' AS DoNotTrack
		,	0 AS Cookies
		,	'sample' AS Canvas
		,	'sample' AS Fonts
		,	'sample' AS Vendor
		,	'sample' AS GLRenderer
		,	'sample' AS Plugins
		,	'sample' AS Languages
		,	'sample' AS Resolution
		,	'sample' AS Timezone
	LIMIT 10;
	
    /*
    
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
    */
    
END$$

DELIMITER ;