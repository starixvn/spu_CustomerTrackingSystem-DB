/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_DeviceEvolution_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_DeviceEvolution_Get`(
		IN ip_BatchSize INT UNSIGNED
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
            CALL DCS_DataCenter.DCS_DC_Transform_DeviceEvolution_Get(50);
	*/
	
    SELECT 	0 AS TransID
		,	1 AS RawFingerPrintID
		,	'1,2,3' AS RawFingerPrintIDs
		,	'sample' AS UserAgent
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
		,	'sample' AS Timezone;
    
	
END$$
DELIMITER ;
