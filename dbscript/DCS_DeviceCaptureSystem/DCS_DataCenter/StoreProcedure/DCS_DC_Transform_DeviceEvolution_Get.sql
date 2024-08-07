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
    DECLARE CONST_MINID_FP_DEVICEEVOLUTION	INT DEFAULT 23;
	DECLARE lv_Max_FP_DeviceEvolutionID  	BIGINT UNSIGNED;
    
	SET lv_Max_FP_DeviceEvolutionID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_MINID_FP_DEVICEEVOLUTION);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerprintAccount;
    
	CREATE TEMPORARY TABLE Temp_DeviceFingerprintAccount(
			ID						BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	FP_FingerPrintID		BIGINT UNSIGNED
		,	AccountID				BIGINT UNSIGNED
		,	FP_FingerPrintIDRef		LONGTEXT
	);
    
    INSERT INTO Temp_DeviceFingerprintAccount(ID, FP_FingerPrintID, AccountID)
	SELECT 	ID
		,	FP_FingerPrintID
		,	AccountID
    FROM DCS_DataCenter.FP_DeviceFingerprintAccount
    WHERE ID > lv_Max_FP_DeviceEvolutionID
		AND DeviceID = 0
    ORDER BY ID ASC
    LIMIT ip_BatchSize;
    
    
    UPDATE Temp_DeviceFingerprintAccount AS tmp
	INNER JOIN (
		SELECT 	dfa.AccountID
			,	GROUP_CONCAT(dfa.FP_FingerPrintID ORDER BY dfa.ID DESC SEPARATOR ',') AS FP_FingerPrintIDRef
		FROM (
			SELECT 	AccountID
				,	ID
                ,	FP_FingerPrintID
                ,	ROW_NUMBER() OVER (PARTITION BY AccountID ORDER BY ID DESC) AS rn
			FROM DCS_DataCenter.FP_DeviceFingerprintAccount
			WHERE DeviceID > 0
		) dfa
		WHERE rn <= 10
		GROUP BY dfa.AccountID
	) AS subquery ON tmp.AccountID = subquery.AccountID
	SET tmp.FP_FingerPrintIDRef = subquery.FP_FingerPrintIDRef;
    
	select 	tmp.ID
		,	tmp.FP_FingerPrintID
		,	tmp.FP_FingerPrintIDRef
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
	FROM Temp_DeviceFingerprintAccount AS tmp
		LEFT JOIN DCS_DataCenter.FP_FingerPrint AS fp ON fp.ID = tmp.FP_FingerprintID
		LEFT JOIN DCS_DataCenter.FP_EvolvedMapping AS em ON em.FP_FingerprintID = tmp.FP_FingerprintID
		LEFT JOIN DCS_DataCenter.FP_FingerPrintExtra AS fpe ON fpe.ID = em.FP_FingerPrintExtraID;
    
END$$
DELIMITER ;
