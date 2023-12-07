/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_ArchiveData_ModifiedDate_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_ArchiveData_ModifiedDate_Update`(
	ip_BatchSize INT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	20230821@Jonathan.Doan
		Task:		Update the ModifiedDate of tables that require archiving.
		DB:			DCS_Extra
		Original:

		Revisions:
			- 20230821@Jonathan.Doan: Created [Redmine ID: #191960]
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
            
		Param's Explanation (filtered by):

		Example:
			CALL DCS_ET_ArchiveData_ModifiedDate_Update(100);
	*/ 
    DECLARE CONST_TRANS07_SYSTEMARCHIVEID INT DEFAULT 4963733;
    DECLARE lv_MaxTransID BIGINT UNSIGNED;
    
    SELECT VValue
    INTO lv_MaxTransID
    FROM DCS_Extra.SystemSetting
    WHERE ID = CONST_TRANS07_SYSTEMARCHIVEID;


    /*******INIT TEMPORARY TABLE************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction07;
	CREATE TEMPORARY TABLE Temp_Transaction07(
        	TransID				BIGINT UNSIGNED PRIMARY KEY
        ,	BotComponentID		BIGINT UNSIGNED DEFAULT NULL
        ,	CookieID			BIGINT UNSIGNED DEFAULT NULL
        ,	RawUserAgentID		BIGINT UNSIGNED DEFAULT NULL
        ,	RawFingerPrintID	BIGINT UNSIGNED DEFAULT NULL
        ,	BrowserInstanceID	BIGINT UNSIGNED DEFAULT NULL
        ,	FPDeviceID			BIGINT UNSIGNED DEFAULT NULL
        ,	CreatedDate			DATETIME
        , 	INDEX IX_Temp_Transaction07_CreatedDate(CreatedDate)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BotComponent;
	CREATE TEMPORARY TABLE Temp_BotComponent(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cookie;
	CREATE TEMPORARY TABLE Temp_Cookie(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawFingerPrint;
	CREATE TEMPORARY TABLE Temp_RawFingerPrint(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInstance;
	CREATE TEMPORARY TABLE Temp_BrowserInstance(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FPDevice;
	CREATE TEMPORARY TABLE Temp_FPDevice(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TEMPORARY TABLE Temp_Account(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    /*******GET DATA Transaction07********************/
    INSERT INTO Temp_Transaction07(TransID, BotComponentID, CookieID, RawUserAgentID, RawFingerPrintID, BrowserInstanceID, FPDeviceID, CreatedDate)
    SELECT 	TransID
        ,	BotComponentID
        ,	CookieID
        ,	RawUserAgentID
        ,	RawFingerPrintID
        ,	BrowserInstanceID
        ,	FPDeviceID
        ,	CreatedDate
	FROM DCS_Extra.Transaction07
	WHERE TransID > lv_MaxTransID
	LIMIT ip_BatchSize;
    
    /*******INIT DATA********************/
    INSERT INTO Temp_BotComponent(ID, MaxCreatedDate)
    SELECT 	BotComponentID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE BotComponentID IS NOT NULL
    GROUP BY BotComponentID;
    
    INSERT INTO Temp_Cookie(ID, MaxCreatedDate)
    SELECT 	CookieID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE CookieID IS NOT NULL
    GROUP BY CookieID;
    
    INSERT INTO Temp_RawUserAgent(ID, MaxCreatedDate)
    SELECT 	RawUserAgentID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE RawUserAgentID IS NOT NULL
    GROUP BY RawUserAgentID;
    
    INSERT INTO Temp_RawFingerPrint(ID, MaxCreatedDate)
    SELECT 	RawFingerPrintID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE RawFingerPrintID IS NOT NULL
    GROUP BY RawFingerPrintID;
    
    INSERT INTO Temp_BrowserInstance(ID, MaxCreatedDate)
    SELECT 	BrowserInstanceID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE BrowserInstanceID IS NOT NULL
    GROUP BY BrowserInstanceID;
    
    INSERT INTO Temp_FPDevice(ID, MaxCreatedDate)
    SELECT 	FPDeviceID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE FPDeviceID IS NOT NULL
    GROUP BY FPDeviceID;

    /*******UPDATE ModifiedDate********************/
	UPDATE DCS_Extra.BotComponent AS main
		INNER JOIN Temp_BotComponent AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxCreatedDate;
    
	UPDATE DCS_Extra.Cookie AS main
		INNER JOIN Temp_Cookie AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxCreatedDate;
    
	UPDATE DCS_Extra.RawUserAgent AS main
		INNER JOIN Temp_RawUserAgent AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxCreatedDate;
    
	UPDATE DCS_Extra.RawFingerPrint AS main
		INNER JOIN Temp_RawFingerPrint AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxCreatedDate;
    
	UPDATE DCS_Extra.BrowserInstance AS main
		INNER JOIN Temp_BrowserInstance AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxCreatedDate;
    
	UPDATE DCS_Extra.FPDevice AS main
		INNER JOIN Temp_FPDevice AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxCreatedDate;
    
    
    /*******UPDATE SystemSetting MaxTransID********************/
    SELECT MAX(TransID)
    INTO lv_MaxTransID
    FROM Temp_Transaction07;
    
    IF lv_MaxTransID IS NOT NULL
    THEN
		UPDATE DCS_Extra.SystemSetting
		SET VValue = lv_MaxTransID
		WHERE ID = CONST_TRANS07_SYSTEMARCHIVEID;
    END IF;
END$$

DELIMITER ;