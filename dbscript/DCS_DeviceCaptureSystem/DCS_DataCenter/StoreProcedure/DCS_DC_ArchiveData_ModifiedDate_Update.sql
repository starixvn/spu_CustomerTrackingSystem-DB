/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_ModifiedDate_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_ModifiedDate_Update`(
	ip_BatchSize INT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	20230807@Jonathan.Doan
		Task:		Update the ModifiedDate of tables that require archiving.
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20230807@Jonathan.Doan: Created [Redmine ID: #191960]
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
            
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_ArchiveData_ModifiedDate_Update(100);
	*/ 
    DECLARE CONST_TRANS07_SYSTEMARCHIVEID INT DEFAULT 4963733;
    DECLARE lv_MaxTransID BIGINT UNSIGNED;
    
    SELECT VValue
    INTO lv_MaxTransID
    FROM DCS_DataCenter.SystemSetting
    WHERE ID = CONST_TRANS07_SYSTEMARCHIVEID;


    /*******INIT TEMPORARY TABLE************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction07;
	CREATE TEMPORARY TABLE Temp_Transaction07(
        	TransID					BIGINT UNSIGNED PRIMARY KEY
        ,	BotComponentID			BIGINT UNSIGNED DEFAULT NULL
        ,	FP_TaggingID			BIGINT UNSIGNED DEFAULT NULL
        ,	FP_FingerPrintID		BIGINT UNSIGNED DEFAULT NULL
        ,	FP_FingerPrintExtraID	BIGINT UNSIGNED DEFAULT NULL
        ,	FP_UserAgentID			BIGINT UNSIGNED DEFAULT NULL
        ,	FP_DeviceID				BIGINT UNSIGNED DEFAULT NULL
        ,	CreatedDate				DATE
        , 	INDEX IX_Temp_Transaction07_CreatedDate(CreatedDate)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BotComponent;
	CREATE TEMPORARY TABLE Temp_BotComponent(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FP_Tagging;
	CREATE TEMPORARY TABLE Temp_FP_Tagging(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FP_FingerPrint;
	CREATE TEMPORARY TABLE Temp_FP_FingerPrint(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FP_FingerPrintExtra;
	CREATE TEMPORARY TABLE Temp_FP_FingerPrintExtra(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FP_UserAgent;
	CREATE TEMPORARY TABLE Temp_FP_UserAgent(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FP_Device;
	CREATE TEMPORARY TABLE Temp_FP_Device(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxCreatedDate		DATETIME
    );
    
    /*******GET DATA Transaction07********************/
    INSERT INTO Temp_Transaction07(TransID, BotComponentID, FP_TaggingID, FP_FingerPrintID, FP_FingerPrintExtraID, FP_UserAgentID, FP_DeviceID, CreatedDate)
    SELECT 	TransID
        ,	BotComponentID
        ,	FP_TaggingID
        ,	FP_FingerPrintID
        ,	FP_FingerPrintExtraID
        ,	FP_UserAgentID
        ,	FP_DeviceID
        ,	CreatedDate
	FROM DCS_DataCenter.Transaction07
	WHERE TransID > lv_MaxTransID
	LIMIT ip_BatchSize;
    
    /*******INIT DATA********************/
    INSERT INTO Temp_BotComponent(ID, MaxCreatedDate)
    SELECT 	BotComponentID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE BotComponentID IS NOT NULL
    GROUP BY BotComponentID;
    
    INSERT INTO Temp_FP_Tagging(ID, MaxCreatedDate)
    SELECT  FP_TaggingID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE FP_TaggingID IS NOT NULL
    GROUP BY FP_TaggingID;
    
    INSERT INTO Temp_FP_FingerPrint(ID, MaxCreatedDate)
    SELECT 	FP_FingerPrintID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE FP_FingerPrintID IS NOT NULL
    GROUP BY FP_FingerPrintID;
    
    INSERT INTO Temp_FP_FingerPrintExtra(ID, MaxCreatedDate)
    SELECT 	FP_FingerPrintExtraID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE FP_FingerPrintExtraID IS NOT NULL
    GROUP BY FP_FingerPrintExtraID;
    
    INSERT INTO Temp_FP_UserAgent(ID, MaxCreatedDate)
    SELECT 	FP_UserAgentID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE FP_UserAgentID IS NOT NULL
    GROUP BY FP_UserAgentID;
    
    INSERT INTO Temp_FP_Device(ID, MaxCreatedDate)
    SELECT 	FP_DeviceID AS ID
		,	MAX(CreatedDate) AS MaxCreatedDate
    FROM Temp_Transaction07
    WHERE FP_DeviceID IS NOT NULL
    GROUP BY FP_DeviceID;

    /*******UPDATE BotComponent********************/
    DELETE tmp
    FROM Temp_BotComponent AS tmp
		INNER JOIN DCS_DataCenter.FP_LastModifiedDate AS lmd ON lmd.TableName = 'BotComponent' 
															AND lmd.RecordID = tmp.ID
	WHERE lmd.LastModifiedDate >= tmp.MaxCreatedDate;
    
    INSERT INTO DCS_DataCenter.FP_LastModifiedDate(TableName, RecordID, LastModifiedDate)
    SELECT	'BotComponent' 	AS TableName
		,	ID 				AS RecordID
		,	MaxCreatedDate	AS LastModifiedDate
	FROM Temp_BotComponent
    ON DUPLICATE KEY UPDATE LastModifiedDate = VALUES(LastModifiedDate),
							ModifiedTime = NOW();

    /*******UPDATE FP_Tagging********************/
    DELETE tmp
    FROM Temp_FP_Tagging AS tmp
		INNER JOIN DCS_DataCenter.FP_LastModifiedDate AS lmd ON lmd.TableName = 'FP_Tagging' 
															AND lmd.RecordID = tmp.ID
	WHERE lmd.LastModifiedDate >= tmp.MaxCreatedDate;
    
    INSERT INTO DCS_DataCenter.FP_LastModifiedDate(TableName, RecordID, LastModifiedDate)
    SELECT	'FP_Tagging' 	AS TableName
		,	ID 				AS RecordID
		,	MaxCreatedDate	AS LastModifiedDate
	FROM Temp_FP_Tagging
    ON DUPLICATE KEY UPDATE LastModifiedDate = VALUES(LastModifiedDate),
							ModifiedTime = NOW();

    /*******UPDATE FP_FingerPrint********************/
    DELETE tmp
    FROM Temp_FP_FingerPrint AS tmp
		INNER JOIN DCS_DataCenter.FP_LastModifiedDate AS lmd ON lmd.TableName = 'FP_FingerPrint' 
															AND lmd.RecordID = tmp.ID
	WHERE lmd.LastModifiedDate >= tmp.MaxCreatedDate;
    
    INSERT INTO DCS_DataCenter.FP_LastModifiedDate(TableName, RecordID, LastModifiedDate)
    SELECT	'FP_FingerPrint' 	AS TableName
		,	ID 				AS RecordID
		,	MaxCreatedDate	AS LastModifiedDate
	FROM Temp_FP_FingerPrint
    ON DUPLICATE KEY UPDATE LastModifiedDate = VALUES(LastModifiedDate),
							ModifiedTime = NOW();

    /*******UPDATE FP_FingerPrintExtra********************/
    DELETE tmp
    FROM Temp_FP_FingerPrintExtra AS tmp
		INNER JOIN DCS_DataCenter.FP_LastModifiedDate AS lmd ON lmd.TableName = 'FP_FingerPrintExtra' 
															AND lmd.RecordID = tmp.ID
	WHERE lmd.LastModifiedDate >= tmp.MaxCreatedDate;
    
    INSERT INTO DCS_DataCenter.FP_LastModifiedDate(TableName, RecordID, LastModifiedDate)
    SELECT	'FP_FingerPrintExtra' 	AS TableName
		,	ID 				AS RecordID
		,	MaxCreatedDate	AS LastModifiedDate
	FROM Temp_FP_FingerPrintExtra
    ON DUPLICATE KEY UPDATE LastModifiedDate = VALUES(LastModifiedDate),
							ModifiedTime = NOW();

    /*******UPDATE FP_UserAgent********************/
    DELETE tmp
    FROM Temp_FP_UserAgent AS tmp
		INNER JOIN DCS_DataCenter.FP_LastModifiedDate AS lmd ON lmd.TableName = 'FP_UserAgent' 
															AND lmd.RecordID = tmp.ID
	WHERE lmd.LastModifiedDate >= tmp.MaxCreatedDate;
    
    INSERT INTO DCS_DataCenter.FP_LastModifiedDate(TableName, RecordID, LastModifiedDate)
    SELECT	'FP_UserAgent' 	AS TableName
		,	ID 				AS RecordID
		,	MaxCreatedDate	AS LastModifiedDate
	FROM Temp_FP_UserAgent
    ON DUPLICATE KEY UPDATE LastModifiedDate = VALUES(LastModifiedDate),
							ModifiedTime = NOW();

    /*******UPDATE FP_Device********************/
    DELETE tmp
    FROM Temp_FP_Device AS tmp
		INNER JOIN DCS_DataCenter.FP_LastModifiedDate AS lmd ON lmd.TableName = 'FP_Device' 
															AND lmd.RecordID = tmp.ID
	WHERE lmd.LastModifiedDate >= tmp.MaxCreatedDate;
    
    INSERT INTO DCS_DataCenter.FP_LastModifiedDate(TableName, RecordID, LastModifiedDate)
    SELECT	'FP_Device' 	AS TableName
		,	ID 				AS RecordID
		,	MaxCreatedDate	AS LastModifiedDate
	FROM Temp_FP_Device
    ON DUPLICATE KEY UPDATE LastModifiedDate = VALUES(LastModifiedDate),
							ModifiedTime = NOW();
    
    /*******UPDATE SystemSetting MaxTransID********************/
    SELECT MAX(TransID)
    INTO lv_MaxTransID
    FROM Temp_Transaction07;
    
    IF lv_MaxTransID IS NOT NULL
    THEN
		UPDATE DCS_DataCenter.SystemSetting
		SET VValue = lv_MaxTransID
		WHERE ID = CONST_TRANS07_SYSTEMARCHIVEID;
    END IF;
END$$

DELIMITER ;


			CALL DCS_DC_ArchiveData_ModifiedDate_Update(100);