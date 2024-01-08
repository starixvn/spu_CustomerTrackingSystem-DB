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
			ID								INT UNSIGNED		NOT NULL AUTO_INCREMENT PRIMARY KEY
        ,	AccountID						BIGINT UNSIGNED		NOT NULL
        ,	DeviceID						BIGINT UNSIGNED		DEFAULT 0
        ,	FPDeviceID						BIGINT UNSIGNED		DEFAULT 0
        ,	SubscriberID					BIGINT UNSIGNED		
        ,	CreatedTime						TIMESTAMP(4)		
        ,	CreatedDate						DATETIME			
		,	IsNewRecordAssociation			TINYINT		 		DEFAULT 1
		,	IsNewRecordAssociationNew		TINYINT		 		DEFAULT 1
		,	IsNewRecordMapping				TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_AssociationInsert(AccountID, DeviceID, FPDeviceID, SubscriberID, CreatedTime, CreatedDate)
	SELECT 	tmp.AccountID
		,	IFNULL(tmp.DeviceID, 0) AS DeviceID
		,	IFNULL(tmp.FPDeviceID, 0) AS FPDeviceID
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
	GROUP BY tmp.AccountID, tmp.DeviceID, FPDeviceID;
    
    /* === Add index === */
	ALTER TABLE Temp_AssociationInsert
	ADD INDEX IX_Temp_AssociationInsert_AccountID_DeviceID (AccountID, DeviceID),
	ADD INDEX IX_Temp_AssociationInsert_AccountID_FPDeviceID (AccountID, FPDeviceID);
    
    /* === Insert into Association === */
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_Extra.Association AS ass ON ass.AccountID = tmp.AccountID 
													AND ass.DeviceID = tmp.DeviceID
    SET tmp.IsNewRecordAssociation = 0;
    
	INSERT IGNORE INTO DCS_Extra.Association(AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertTime)
	SELECT	AccountID
		,	DeviceID
		,	SubscriberID
		,	CreatedTime
		,	CreatedDate
		,	lv_CreatedDate AS InsertTime
	FROM Temp_AssociationInsert
    WHERE IsNewRecordAssociation = 1
		AND DeviceID > 0;
    
    /* === Insert into AssociationNew === */
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_Extra.AssociationNew AS ass ON ass.AccountID = tmp.AccountID 
													AND ass.DeviceID = (CASE WHEN tmp.FPDeviceID = 0 THEN tmp.DeviceID ELSE tmp.FPDeviceID END)
    SET tmp.IsNewRecordAssociationNew = 0;
    
	INSERT IGNORE INTO DCS_Extra.AssociationNew(AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertedTime)
	SELECT	AccountID
		,	(CASE WHEN FPDeviceID = 0 THEN DeviceID ELSE FPDeviceID END) AS DeviceID
		,	SubscriberID
		,	CreatedTime
		,	CreatedDate
		,	lv_CreatedDate AS InsertedTime
	FROM Temp_AssociationInsert
    WHERE IsNewRecordAssociationNew = 1
		AND (FPDeviceID > 0 OR DeviceID > 0);
    
    /* === Insert into AssociationMapping === */
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_Extra.AssociationMapping AS ass ON ass.AccountID = tmp.AccountID 
													AND ass.DeviceID = tmp.DeviceID
													AND ass.FPDeviceID = tmp.FPDeviceID
    SET tmp.IsNewRecordMapping = 0;
    
	INSERT IGNORE INTO DCS_Extra.AssociationMapping(AccountID, DeviceID, FPDeviceID, SubscriberID, CreatedTime, CreatedDate, InsertedTime)
	SELECT	AccountID
		,	DeviceID
		,	FPDeviceID
		,	SubscriberID
		,	CreatedTime
		,	CreatedDate
		,	lv_CreatedDate AS InsertedTime
	FROM Temp_AssociationInsert
    WHERE IsNewRecordMapping = 1
		AND (FPDeviceID > 0 OR DeviceID > 0);
END$$

DELIMITER ;
