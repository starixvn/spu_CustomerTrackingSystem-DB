/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transform_Association_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transform_Association_Insert`(
		IN ip_AssociationJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231205@Jonathan.Doan
		Task : Insert into DCS_Extra.Association
		DB: DCS_Extra
		Original:

		Revisions:
			- 20231205@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Transform_Association_Insert('[{"DeviceID": 3, "AccountID": 300016, "FPDeviceID": null, "CreatedDate": "2023-11-17 00:00:00.000000", "CreatedTime": "2023-11-17 10:33:46.527500", "SubscriberID": 2}]');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationInsert;
        
	CREATE TEMPORARY TABLE Temp_AssociationInsert(
			ID						INT UNSIGNED		NOT NULL AUTO_INCREMENT PRIMARY KEY
        ,	AccountID				BIGINT UNSIGNED		NOT NULL
        ,	DeviceID				BIGINT UNSIGNED		NOT NULL
        ,	FPDeviceID				BIGINT UNSIGNED		DEFAULT 0
        ,	SubscriberID			BIGINT UNSIGNED		
        ,	CreatedTime				TIMESTAMP(4)		
        ,	CreatedDate				DATETIME			
		,	IsNewRecord				TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_AssociationInsert(AccountID, DeviceID, FPDeviceID, SubscriberID, CreatedTime, CreatedDate)
	SELECT 	tmp.AccountID
		,	tmp.DeviceID
		,	IFNULL(tmp.FPDeviceID,0) AS FPDeviceID
		,	MIN(tmp.SubscriberID) AS SubscriberID
		,	MIN(tmp.CreatedTime) AS CreatedTime
		,	MIN(tmp.CreatedDate) AS CreatedDate
    FROM JSON_TABLE(
			ip_AssociationJson,
			 "$[*]" COLUMNS(
							AccountID			BIGINT UNSIGNED	PATH "$.AccountID"
						,	DeviceID			BIGINT UNSIGNED PATH "$.DeviceID"
						,	FPDeviceID			BIGINT UNSIGNED PATH "$.FPDeviceID"
						,	SubscriberID		INT 			PATH "$.SubscriberID"
						,	CreatedTime			TIMESTAMP(4) 	PATH "$.CreatedTime"
						,	CreatedDate			DATETIME	 	PATH "$.CreatedDate"
					)
		) AS tmp
	WHERE tmp.AccountID IS NOT NULL
		AND tmp.DeviceID IS NOT NULL
	GROUP BY tmp.AccountID, tmp.DeviceID, tmp.FPDeviceID;
    
    /* === Add index === */
	ALTER TABLE Temp_AssociationInsert
	ADD INDEX IX_Temp_AssociationInsert_AccountID_DeviceID_FPDeviceID (AccountID, DeviceID, FPDeviceID);
    
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_Extra.Association AS ass ON ass.AccountID = tmp.AccountID 
													AND ass.DeviceID = tmp.DeviceID
													AND ass.FPDeviceID = tmp.FPDeviceID
    SET tmp.IsNewRecord = 0;
    
	INSERT IGNORE INTO DCS_Extra.Association(AccountID, DeviceID, FPDeviceID, SubscriberID, CreatedTime, CreatedDate, InsertTime)
	SELECT	AccountID
		,	DeviceID
		,	FPDeviceID
		,	SubscriberID
		,	CreatedTime
		,	CreatedDate
		,	lv_CreatedDate AS InsertTime
	FROM Temp_AssociationInsert
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
