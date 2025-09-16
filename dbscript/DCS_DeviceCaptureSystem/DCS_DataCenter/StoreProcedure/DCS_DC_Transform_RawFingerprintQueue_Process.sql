/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawFingerprintQueue_Process`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawFingerprintQueue_Process`(
	IN ip_BatchSize INT
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20250822@Casey.Huynh
		Task : Transform Pattern Group
		DB: DCS_DataCenter
		Original:

		Revisions:
            - 20250826@Casey.Huynh: Created, AI Power Device Fingerprint AND Remove FPJs [Redmine ID: #236716]

		Param's Explanation (filtered by):
		Example:
			
	*/
	DECLARE CONST_TYPE_HARDWARE		INT DEFAULT 1;
    DECLARE CONST_TYPE_GRAPHIC		INT DEFAULT 2;
    DECLARE CONST_TYPE_AUDIO		INT DEFAULT 3;
    DECLARE CONST_TYPE_BROWSER		INT DEFAULT 4;
    DECLARE CONST_TYPE_PREFERENCES	INT DEFAULT 5;
    
	DECLARE CONST_TYPE_PATTERN01	INT DEFAULT 1;
    DECLARE CONST_TYPE_PATTERN02	INT DEFAULT 2;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawFingerprintQueue;
	CREATE TEMPORARY TABLE Temp_RawFingerprintQueue(
			ID					BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	FPPatternID01		BIGINT UNSIGNED
		,	FPPatternID02		BIGINT UNSIGNED
		,	HardwareCode		VARCHAR(32)
		,	GraphicCode		VARCHAR(32)
		,	AudioCode			VARCHAR(32)
		,	BrowserCode			VARCHAR(32)
		,	PreferencesCode		VARCHAR(32)
		,	HardwareDetails		LONGTEXT
		,	GraphicDetails		LONGTEXT
		,	AudioDetails		LONGTEXT
		,	BrowserDetails		LONGTEXT
		,	PreferencesDetails	LONGTEXT
		,	CreatedDate			DATE
        
        ,	INDEX IX_RawFingerprintQueue_HardwareCode(HardwareCode)
        ,	INDEX IX_RawFingerprintQueue_GraphicCode(GraphicCode)
        ,	INDEX IX_RawFingerprintQueue_AudioCode(AudioCode)
        ,	INDEX IX_RawFingerprintQueue_BrowserCode(BrowserCode)
        ,	INDEX IX_RawFingerprintQueue_PreferencesCode(PreferencesCode)
	);     
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Hardware;
	CREATE TEMPORARY TABLE Temp_Hardware(
			HardwareCode		VARCHAR(32) NOT NULL PRIMARY KEY
        ,	FPGroupHardwareID	BIGINT UNSIGNED
        ,	NewUsedDate			DATE		
	
		,	INDEX IX_Temp_Hardware_FPGroupHardwareID(FPGroupHardwareID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graphic;
	CREATE TEMPORARY TABLE Temp_Graphic(
			GraphicCode			VARCHAR(32) NOT NULL PRIMARY KEY
        ,	FPGroupGraphicID	BIGINT UNSIGNED
        ,	NewUsedDate			DATE		
	
		,	INDEX IX_Temp_Graphic_FPGroupGraphicID(FPGroupGraphicID)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Audio;
	CREATE TEMPORARY TABLE Temp_Audio(
			AudioCode		VARCHAR(32) NOT NULL PRIMARY KEY
        ,	FPGroupAudioID	BIGINT UNSIGNED
        ,	NewUsedDate			DATE		
	
		,	INDEX IX_Temp_Audio_FPGroupAudioID(FPGroupAudioID)
    );    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Browser;
	CREATE TEMPORARY TABLE Temp_Browser(
			BrowserCode			VARCHAR(32) NOT NULL PRIMARY KEY
        ,	FPGroupBrowserID	BIGINT UNSIGNED
        ,	NewUsedDate			DATE		
	
		,	INDEX IX_Temp_Browser_FPGroupBrowserID(FPGroupBrowserID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Preferences;
	CREATE TEMPORARY TABLE Temp_Preferences(
			PreferencesCode		VARCHAR(32) NOT NULL PRIMARY KEY
        ,	FPGroupPreferencesID	BIGINT UNSIGNED
        ,	NewUsedDate			DATE		
	
		,	INDEX IX_Temp_Preferences_FPGroupPreferencesID(FPGroupPreferencesID)
    );  
    #=============================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_FPPatternGroup;
	CREATE TEMPORARY TABLE Temp_FPPatternGroup(
			FPPatternID 	BIGINT UNSIGNED NOT NULL
		,	FPPatternType	TINYINT NOT NULL COMMENT 'Pattern Group Combinition'
        ,	FPGroupType 	TINYINT UNSIGNED NOT NULL COMMENT '1:Hardware, 2:Graphic, 3.Audio, 4. Browser, 5.Prereference'
		,	FPGroupID 		BIGINT UNSIGNED	NOT NULL		
		
		,	PRIMARY KEY PK_FPPatternGroup_FPCode(FPPatternID, FPGroupType, FPGroupID)
	);
    
    INSERT INTO Temp_RawFingerprintQueue(ID, FPPatternID01, FPPatternID02, HardwareCode, GraphicCode, AudioCode, BrowserCode, PreferencesCode, HardwareDetails, GraphicDetails, AudioDetails, BrowserDetails, PreferencesDetails, CreatedDate)
	SELECT	que.ID
		,	que.FPPatternID01
		,	que.FPPatternID02
		,	que.HardwareCode
		,	que.GraphicCode
		,	que.AudioCode
		,	que.BrowserCode
		,	que.PreferencesCode
		,	que.HardwareDetails
		,	que.GraphicDetails
		,	que.AudioDetails
		,	que.BrowserDetails
		,	que.PreferencesDetails
		,	que.CreatedDate
    FROM DCS_DataCenter.RawFingerprintQueue AS que
	LIMIT ip_BatchSize;

    #===================================================================================
    #=======================HARDWARE DEAILS=============================================    
    INSERT INTO Temp_Hardware(HardwareCode, FPGroupHardwareID, NewUsedDate)
    WITH CTE_Hardware AS(
		SELECT	tmpQue.HardwareCode
			,	MAX(tmpQue.CreatedDate) AS NewUsedDate
        FROM Temp_RawFingerprintQueue AS tmpQue
        GROUP BY tmpQue.HardwareCode
    )
    SELECT 	DISTINCT cte.HardwareCode
		,	hw.FPGroupHardwareID
        ,	cte.NewUsedDate
	FROM CTE_Hardware AS cte
		LEFT JOIN DCS_DataCenter.FPGroupHardware AS hw ON cte.HardwareCode = hw.HardwareCode;
        
    #======UPDATE FOR EXISTING GROUP LastUsedDate============    
    UPDATE DCS_DataCenter.FPGroupHardware AS hw
		INNER JOIN Temp_Hardware AS tmpHw ON tmpHw.FPGroupHardwareID = hw.FPGroupHardwareID
	SET LastUsedDate = NewUsedDate
    WHERE LastUsedDate < NewUsedDate;

	#======INSERT NEW GROUP Details=============================
	INSERT IGNORE INTO DCS_DataCenter.FPGroupHardware(HardwareCode, HardwareDetails, CreatedDate, LastUsedDate)
	SELECT	tmpHw.HardwareCode
		,	ltr.HardwareDetails
		,	tmpHw.NewUsedDate
		,	tmpHw.NewUsedDate AS LastUsedDate
	FROM Temp_Hardware AS tmpHw
	,	LATERAL (	SELECT tmpQue.HardwareDetails
					FROM Temp_RawFingerprintQueue AS tmpQue
					WHERE tmpQue.HardwareCode = tmpHw.HardwareCode
                    LIMIT 1
        ) AS ltr
    WHERE tmpHw.FPGroupHardwareID IS NULL
    ON DUPLICATE KEY UPDATE LastUsedDate = GREATEST(LastUsedDate, NewUsedDate);
    
    UPDATE Temp_Hardware AS tmpHw
		INNER JOIN DCS_DataCenter.FPGroupHardware AS hw ON hw.HardwareCode = tmpHw.HardwareCode
    SET tmpHw.FPGroupHardwareID = hw.FPGroupHardwareID
    WHERE tmpHw.FPGroupHardwareID IS NULL;
    
    #===================INSERT Temp_FPPatternGroup========================================================
	
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID01
		,	CONST_TYPE_PATTERN01 AS FPPatternType
		,	tmpHw.FPGroupHardwareID
		,	CONST_TYPE_HARDWARE AS FPGroupType
	FROM Temp_Hardware AS tmpHw
		,	LATERAL (	SELECT tmpQue.FPPatternID01
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.HardwareCode = tmpHw.HardwareCode
						LIMIT 1
        ) AS ltr;    
        
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID02
		,	CONST_TYPE_PATTERN02 AS FPPatternType
		,	tmpHw.FPGroupHardwareID
		,	CONST_TYPE_HARDWARE AS FPGroupType
	FROM Temp_Hardware AS tmpHw
		,	LATERAL (	SELECT tmpQue.FPPatternID02
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.HardwareCode = tmpHw.HardwareCode
						LIMIT 1
        ) AS ltr;
	
    #===================================================================================
    #=======================Graphic DEAILS=============================================    
    INSERT INTO Temp_Graphic(GraphicCode, FPGroupGraphicID, NewUsedDate)
    WITH CTE_Graphic AS(
		SELECT	tmpQue.GraphicCode
			,	MAX(tmpQue.CreatedDate) AS NewUsedDate
        FROM Temp_RawFingerprintQueue AS tmpQue
        GROUP BY tmpQue.GraphicCode
    )
    SELECT 	DISTINCT cte.GraphicCode
		,	gp.FPGroupGraphicID
        ,	cte.NewUsedDate
	FROM CTE_Graphic AS cte
		LEFT JOIN DCS_DataCenter.FPGroupGraphic AS gp ON cte.GraphicCode = gp.GraphicCode;

    #======UPDATE FOR EXISTING GROUP LastUsedDate============    
    UPDATE DCS_DataCenter.FPGroupGraphic AS gp
		INNER JOIN Temp_Graphic AS tmpGp ON tmpGp.FPGroupGraphicID = gp.FPGroupGraphicID
	SET LastUsedDate = NewUsedDate
    WHERE LastUsedDate < NewUsedDate;

	#======INSERT NEW GROUP Details=============================
	INSERT IGNORE INTO DCS_DataCenter.FPGroupGraphic(GraphicCode, GraphicDetails, CreatedDate, LastUsedDate)
	SELECT	tmpGp.GraphicCode
		,	ltr.GraphicDetails
		,	tmpGp.NewUsedDate
		,	tmpGp.NewUsedDate AS LastUsedDate
	FROM Temp_Graphic AS tmpGp
	,	LATERAL (	SELECT tmpQue.GraphicDetails
					FROM Temp_RawFingerprintQueue AS tmpQue
					WHERE tmpQue.GraphicCode = tmpGp.GraphicCode
                    LIMIT 1
        ) AS ltr
    WHERE tmpGp.FPGroupGraphicID IS NULL
    ON DUPLICATE KEY UPDATE LastUsedDate = GREATEST(LastUsedDate, NewUsedDate);
    
    UPDATE Temp_Graphic AS tmpGp
		INNER JOIN DCS_DataCenter.FPGroupGraphic AS gp ON gp.GraphicCode = tmpGp.GraphicCode
    SET tmpGp.FPGroupGraphicID = gp.FPGroupGraphicID
    WHERE tmpGp.FPGroupGraphicID IS NULL;
    
    #===================INSERT Temp_FPPatternGroup========================================================
	
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID01
		,	CONST_TYPE_PATTERN01 AS FPPatternType
		,	tmpGp.FPGroupGraphicID
		,	CONST_TYPE_GRAPHIC AS FPGroupType
	FROM Temp_Graphic AS tmpGp
		,	LATERAL (	SELECT tmpQue.FPPatternID01
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.GraphicCode = tmpGp.GraphicCode
						LIMIT 1
        ) AS ltr;    
        
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID02
		,	CONST_TYPE_PATTERN02 AS FPPatternType
		,	tmpGp.FPGroupGraphicID
		,	CONST_TYPE_GRAPHIC AS FPGroupType
	FROM Temp_Graphic AS tmpGp
		,	LATERAL (	SELECT tmpQue.FPPatternID02
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.GraphicCode = tmpGp.GraphicCode
						LIMIT 1
        ) AS ltr;
    
    #===================================================================================
    #=======================Audio DEAILS=============================================    
    INSERT INTO Temp_Audio(AudioCode, FPGroupAudioID, NewUsedDate)
    WITH CTE_Audio AS(
		SELECT	tmpQue.AudioCode
			,	MAX(tmpQue.CreatedDate) AS NewUsedDate
        FROM Temp_RawFingerprintQueue AS tmpQue
        GROUP BY tmpQue.AudioCode
    )
    SELECT 	DISTINCT cte.AudioCode
		,	ad.FPGroupAudioID
        ,	cte.NewUsedDate
	FROM CTE_Audio AS cte
		LEFT JOIN DCS_DataCenter.FPGroupAudio AS ad ON cte.AudioCode = ad.AudioCode;
        
    #======UPDATE FOR EXISTING GROUP LastUsedDate============    
    UPDATE DCS_DataCenter.FPGroupAudio AS ad
		INNER JOIN Temp_Audio AS tmpAd ON tmpAd.FPGroupAudioID = ad.FPGroupAudioID
	SET LastUsedDate = NewUsedDate
    WHERE LastUsedDate < NewUsedDate;

	#======INSERT NEW GROUP Details=============================
	INSERT IGNORE INTO DCS_DataCenter.FPGroupAudio(AudioCode, AudioDetails, CreatedDate, LastUsedDate)
	SELECT	tmpAd.AudioCode
		,	ltr.AudioDetails
		,	tmpAd.NewUsedDate
		,	tmpAd.NewUsedDate AS LastUsedDate
	FROM Temp_Audio AS tmpAd
	,	LATERAL (	SELECT tmpQue.AudioDetails
					FROM Temp_RawFingerprintQueue AS tmpQue
					WHERE tmpQue.AudioCode = tmpAd.AudioCode
                    LIMIT 1
        ) AS ltr
    WHERE tmpAd.FPGroupAudioID IS NULL
    ON DUPLICATE KEY UPDATE LastUsedDate = GREATEST(LastUsedDate, NewUsedDate);
    
    UPDATE Temp_Audio AS tmpAd
		INNER JOIN DCS_DataCenter.FPGroupAudio AS ad ON ad.AudioCode = tmpAd.AudioCode
    SET tmpAd.FPGroupAudioID = ad.FPGroupAudioID
    WHERE tmpAd.FPGroupAudioID IS NULL;
	
    #===================================================================================
    #=======================Browser DEAILS=============================================    
    INSERT INTO Temp_Browser(BrowserCode, FPGroupBrowserID, NewUsedDate)
    WITH CTE_Browser AS(
		SELECT	tmpQue.BrowserCode
			,	MAX(tmpQue.CreatedDate) AS NewUsedDate
        FROM Temp_RawFingerprintQueue AS tmpQue
        GROUP BY tmpQue.BrowserCode
    )
    SELECT 	DISTINCT cte.BrowserCode
		,	bs.FPGroupBrowserID
        ,	cte.NewUsedDate
	FROM CTE_Browser AS cte
		LEFT JOIN DCS_DataCenter.FPGroupBrowser AS bs ON cte.BrowserCode = bs.BrowserCode;
        
    #======UPDATE FOR EXISTING GROUP LastUsedDate============    
    UPDATE DCS_DataCenter.FPGroupBrowser AS bs
		INNER JOIN Temp_Browser AS tmpBs ON tmpBs.FPGroupBrowserID = bs.FPGroupBrowserID
	SET LastUsedDate = NewUsedDate
    WHERE LastUsedDate < NewUsedDate;

	#======INSERT NEW GROUP Details=============================
	INSERT IGNORE INTO DCS_DataCenter.FPGroupBrowser(BrowserCode, BrowserDetails, CreatedDate, LastUsedDate)
	SELECT	tmpBs.BrowserCode
		,	ltr.BrowserDetails
		,	tmpBs.NewUsedDate
		,	tmpBs.NewUsedDate AS LastUsedDate
	FROM Temp_Browser AS tmpBs
	,	LATERAL (	SELECT tmpQue.BrowserDetails
					FROM Temp_RawFingerprintQueue AS tmpQue
					WHERE tmpQue.BrowserCode = tmpBs.BrowserCode
                    LIMIT 1
        ) AS ltr
    WHERE tmpBs.FPGroupBrowserID IS NULL
    ON DUPLICATE KEY UPDATE LastUsedDate = GREATEST(LastUsedDate, NewUsedDate);
    
    UPDATE Temp_Browser AS tmpBs
		INNER JOIN DCS_DataCenter.FPGroupBrowser AS bs ON bs.BrowserCode = tmpBs.BrowserCode
    SET tmpBs.FPGroupBrowserID = bs.FPGroupBrowserID
    WHERE tmpBs.FPGroupBrowserID IS NULL;
    
    #===================INSERT Temp_FPPatternGroup========================================================
	
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID01
		,	CONST_TYPE_PATTERN01 AS FPPatternType
		,	tmpBs.FPGroupBrowserID
		,	CONST_TYPE_BROWSER AS FPGroupType
	FROM Temp_Browser AS tmpBs
		,	LATERAL (	SELECT tmpQue.FPPatternID01
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.BrowserCode = tmpBs.BrowserCode
						LIMIT 1
        ) AS ltr;    
        
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID02
		,	CONST_TYPE_PATTERN02 AS FPPatternType
		,	tmpBs.FPGroupBrowserID
		,	CONST_TYPE_BROWSER AS FPGroupType
	FROM Temp_Browser AS tmpBs
		,	LATERAL (	SELECT tmpQue.FPPatternID02
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.BrowserCode = tmpBs.BrowserCode
						LIMIT 1
        ) AS ltr;
    
    #===================================================================================
    #=======================Preferences DEAILS=============================================    
    INSERT INTO Temp_Preferences(PreferencesCode, FPGroupPreferencesID, NewUsedDate)
    WITH CTE_Preferences AS(
		SELECT	tmpQue.PreferencesCode
			,	MAX(tmpQue.CreatedDate) AS NewUsedDate
        FROM Temp_RawFingerprintQueue AS tmpQue
        GROUP BY tmpQue.PreferencesCode
    )
    SELECT 	DISTINCT cte.PreferencesCode
		,	pf.FPGroupPreferencesID
        ,	cte.NewUsedDate
	FROM CTE_Preferences AS cte
		LEFT JOIN DCS_DataCenter.FPGroupPreferences AS pf ON cte.PreferencesCode = pf.PreferencesCode;
        
    #======UPDATE FOR EXISTING GROUP LastUsedDate============    
    UPDATE DCS_DataCenter.FPGroupPreferences AS pf
		INNER JOIN Temp_Preferences AS tmpPf ON tmpPf.FPGroupPreferencesID = pf.FPGroupPreferencesID
	SET LastUsedDate = NewUsedDate
    WHERE LastUsedDate < NewUsedDate;

	#======INSERT NEW GROUP Details=============================
	INSERT IGNORE INTO DCS_DataCenter.FPGroupPreferences(PreferencesCode, PreferencesDetails, CreatedDate, LastUsedDate)
	SELECT	tmpPf.PreferencesCode
		,	ltr.PreferencesDetails
		,	tmpPf.NewUsedDate
		,	tmpPf.NewUsedDate AS LastUsedDate
	FROM Temp_Preferences AS tmpPf
	,	LATERAL (	SELECT tmpQue.PreferencesDetails
					FROM Temp_RawFingerprintQueue AS tmpQue
					WHERE tmpQue.PreferencesCode = tmpPf.PreferencesCode
                    LIMIT 1
        ) AS ltr
    WHERE tmpPf.FPGroupPreferencesID IS NULL
    ON DUPLICATE KEY UPDATE LastUsedDate = GREATEST(LastUsedDate, NewUsedDate);
    
    UPDATE Temp_Preferences AS tmpPf
		INNER JOIN DCS_DataCenter.FPGroupPreferences AS pf ON pf.PreferencesCode = tmpPf.PreferencesCode
    SET tmpPf.FPGroupPreferencesID = pf.FPGroupPreferencesID
    WHERE tmpPf.FPGroupPreferencesID IS NULL;
    
    #===================INSERT Temp_FPPatternGroup========================================================
	
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID01
		,	CONST_TYPE_PATTERN01 AS FPPatternType
		,	tmpPf.FPGroupPreferencesID
		,	CONST_TYPE_PREFERENCES AS FPGroupType
	FROM Temp_Preferences AS tmpPf
		,	LATERAL (	SELECT tmpQue.FPPatternID01
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.PreferencesCode = tmpPf.PreferencesCode
						LIMIT 1
        ) AS ltr;    
        
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID02
		,	CONST_TYPE_PATTERN02 AS FPPatternType
		,	tmpPf.FPGroupPreferencesID
		,	CONST_TYPE_PREFERENCES AS FPGroupType
	FROM Temp_Preferences AS tmpPf
		,	LATERAL (	SELECT tmpQue.FPPatternID02
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.PreferencesCode = tmpPf.PreferencesCode
						LIMIT 1
        ) AS ltr;
	   
    
    #===================INSERT Temp_FPPatternGroup========================================================	
	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID01
		,	CONST_TYPE_PATTERN01 AS FPPatternType
		,	tmpAd.FPGroupAudioID
		,	CONST_TYPE_AUDIO AS FPGroupType
	FROM Temp_Audio AS tmpAd
		,	LATERAL (	SELECT tmpQue.FPPatternID01
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.AudioCode = tmpAd.AudioCode
						LIMIT 1
        ) AS ltr;    

	INSERT INTO Temp_FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	ltr.FPPatternID02
		,	CONST_TYPE_PATTERN02 AS FPPatternType
		,	tmpAd.FPGroupAudioID
		,	CONST_TYPE_AUDIO AS FPGroupType
	FROM Temp_Audio AS tmpAd
		,	LATERAL (	SELECT tmpQue.FPPatternID02
						FROM Temp_RawFingerprintQueue AS tmpQue
						WHERE tmpQue.AudioCode = tmpAd.AudioCode
						LIMIT 1
        ) AS ltr;
	
    #=================FPPatternGroup=========================
    INSERT IGNORE INTO DCS_DataCenter.FPPatternGroup(FPPatternID, FPPatternType, FPGroupID, FPGroupType)
    SELECT	tmpPg.FPPatternID
		,	tmpPg.FPPatternType
        ,	tmpPg.FPGroupID
        ,	tmpPg.FPGroupType
    FROM Temp_FPPatternGroup AS tmpPg;
    
    #=================CLEAN QUEUE============================================
    DELETE que
    FROM DCS_DataCenter.RawFingerprintQueue AS que
		INNER JOIN Temp_RawFingerprintQueue AS tmpQue ON tmpQue.ID = que.ID;
        
END$$

DELIMITER ;
