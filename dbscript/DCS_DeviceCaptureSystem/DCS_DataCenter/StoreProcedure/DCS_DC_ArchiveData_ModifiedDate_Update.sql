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
            
		Param's Explanation (filtered by):

		Example:
			CALL DCS_DC_ArchiveData_ModifiedDate_Update(100);
	*/ 
    DECLARE lv_SystemSettingID INT DEFAULT 4963733;
    DECLARE lv_MaxTransID BIGINT UNSIGNED;
    
    SELECT VValue
    INTO lv_MaxTransID
    FROM DCS_DataCenter.SystemSetting
    WHERE ID = lv_SystemSettingID;


    /*******INIT TEMPORARY TABLE************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction07;
	CREATE TEMPORARY TABLE Temp_Transaction07(
        	TransID				BIGINT UNSIGNED PRIMARY KEY
        ,	BotComponentID		BIGINT UNSIGNED DEFAULT NULL
        ,	TransTime			DATETIME
        , 	INDEX IX_Temp_Transaction07_TransTime(TransTime)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_BotComponent;
	CREATE TEMPORARY TABLE Temp_BotComponent(
        	ID					BIGINT UNSIGNED PRIMARY KEY
        ,	MaxTransTime		DATETIME
    );
    
    /*******GET DATA Transaction07********************/
    INSERT INTO Temp_Transaction07(TransID, BotComponentID, TransTime)
    SELECT 	TransID
        ,	BotComponentID
        ,	TransTime
	FROM DCS_DataCenter.Transaction07
	WHERE TransID > lv_MaxTransID
	LIMIT ip_BatchSize;
    
    /*******INIT DATA********************/
    INSERT INTO Temp_BotComponent(ID, MaxTransTime)
    SELECT 	BotComponentID AS ID
		,	MAX(TransTime) AS MaxTransTime
    FROM Temp_Transaction07
    WHERE BotComponentID IS NOT NULL
    GROUP BY BotComponentID;

    /*******UPDATE ModifiedDate********************/
	UPDATE DCS_DataCenter.BotComponent AS main
		INNER JOIN Temp_BotComponent AS tmp ON tmp.ID = main.ID
	SET main.ModifiedDate = tmp.MaxTransTime;
    
    
    /*******UPDATE SystemSetting MaxTransID********************/
    SELECT MAX(TransID)
    INTO lv_MaxTransID
    FROM Temp_Transaction07;
    
    IF lv_MaxTransID IS NOT NULL
    THEN
		UPDATE DCS_DataCenter.SystemSetting
		SET VValue = lv_MaxTransID
		WHERE ID = lv_SystemSettingID;
    END IF;
END$$

DELIMITER ;