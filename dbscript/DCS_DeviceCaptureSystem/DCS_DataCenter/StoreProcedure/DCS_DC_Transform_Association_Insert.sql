/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Association_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Association_Insert`(
		IN ip_AssociationJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231128@Jonathan.Doan
		Task : Insert into DCS_DataCenter.Association
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231128@Jonathan.Doan: Created [Redmine ID: #196570]
			- 20240806@Jonathan.Doan: Change data flow v6 [Redmine ID: #206403]
            
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_Association_Insert('[{"DeviceID": 4, "AccountID": 1, "FP_DeviceID": 3000001, "CreatedDate": "2023-11-17 00:00:00.000000", "CreatedTime": "2023-11-17 10:33:46.527500", "SubscriberID": 2}]');
			CALL DCS_DC_Transform_Association_Insert('[{"DeviceID": 6, "AccountID": 300016, "FP_DeviceID": null, "CreatedDate": "2023-11-17 00:00:00.000000", "CreatedTime": "2023-11-17 10:33:46.527500", "SubscriberID": 2}]');
        select * from Association;
*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationInsert;
        
	CREATE TEMPORARY TABLE Temp_AssociationInsert(
			ID								INT UNSIGNED		NOT NULL AUTO_INCREMENT PRIMARY KEY
        ,	AccountID						BIGINT UNSIGNED		NOT NULL
        ,	DeviceID						BIGINT UNSIGNED		DEFAULT 0
        ,	FP_DeviceID						BIGINT UNSIGNED		DEFAULT 0
        ,	SubscriberID					BIGINT UNSIGNED		
        ,	CreatedTime						TIMESTAMP(4)		
        ,	CreatedDate						DATETIME			
		,	IsNewRecordAssociation			TINYINT		 		DEFAULT 1
		,	IsNewRecordFPAssociation		TINYINT		 		DEFAULT 1
		,	IsNewRecordMapping				TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_AssociationInsert(AccountID, DeviceID, FP_DeviceID, SubscriberID, CreatedTime, CreatedDate)
	SELECT 	tmp.AccountID
		,	IFNULL(tmp.DeviceID, 0) AS DeviceID
		,	IFNULL(tmp.FP_DeviceID, 0) AS FP_DeviceID
		,	MIN(tmp.SubscriberID) AS SubscriberID
		,	MIN(tmp.CreatedTime) AS CreatedTime
		,	MIN(tmp.CreatedDate) AS CreatedDate
    FROM JSON_TABLE(
			ip_AssociationJson,
			 "$[*]" COLUMNS(
							AccountID			BIGINT UNSIGNED	PATH "$.AccountID"
						,	DeviceID			BIGINT UNSIGNED PATH "$.DeviceID"
						,	FP_DeviceID			BIGINT UNSIGNED PATH "$.FP_DeviceID"
						,	SubscriberID		INT 			PATH "$.SubscriberID"
						,	CreatedTime			TIMESTAMP(4) 	PATH "$.CreatedTime"
						,	CreatedDate			DATETIME	 	PATH "$.CreatedDate"
					)
		) AS tmp
	WHERE tmp.AccountID IS NOT NULL
	GROUP BY tmp.AccountID, tmp.DeviceID, FP_DeviceID;
    
    /* === Add index === */
	ALTER TABLE Temp_AssociationInsert
	ADD INDEX IX_Temp_AssociationInsert_AccountID_DeviceID (AccountID, DeviceID),
	ADD INDEX IX_Temp_AssociationInsert_AccountID_FP_DeviceID (AccountID, FP_DeviceID);
    
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_DataCenter.Association AS ass ON ass.AccountID = tmp.AccountID
													AND ass.DeviceID = tmp.DeviceID
    SET tmp.IsNewRecordAssociation = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.Association(AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertTime)
	SELECT	AccountID
		,	DeviceID
		,	SubscriberID
		,	CreatedTime
		,	CreatedDate
		,	lv_CreatedDate AS InsertTime
	FROM Temp_AssociationInsert
    WHERE IsNewRecordAssociation = 1
		AND DeviceID > 0;
    
    /* === Insert into FP_AssociationMapping === */
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_DataCenter.FP_Association AS ass ON ass.AccountID = tmp.AccountID
														AND ass.DeviceID = (CASE WHEN tmp.FP_DeviceID = 0 THEN tmp.DeviceID ELSE tmp.FP_DeviceID END)
    SET tmp.IsNewRecordFPAssociation = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.FP_Association(AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertedTime)
	SELECT	AccountID
		,	(CASE WHEN FP_DeviceID = 0 THEN DeviceID ELSE FP_DeviceID END) AS DeviceID
		,	SubscriberID
		,	CreatedTime
		,	CreatedDate
		,	lv_CreatedDate AS InsertedTime
	FROM Temp_AssociationInsert
    WHERE IsNewRecordFPAssociation = 1
		AND (FP_DeviceID > 0 OR DeviceID > 0);
    
    /* === Insert into FP_AssociationMapping === */
    UPDATE Temp_AssociationInsert AS tmp
		INNER JOIN DCS_DataCenter.FP_AssociationMapping AS ass ON ass.AccountID = tmp.AccountID 
															AND ass.DeviceID = tmp.DeviceID
															AND ass.FP_DeviceID = tmp.FP_DeviceID
    SET tmp.IsNewRecordMapping = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.FP_AssociationMapping(AccountID, DeviceID, FP_DeviceID, SubscriberID)
	SELECT	AccountID
		,	DeviceID
		,	FP_DeviceID
		,	SubscriberID
	FROM Temp_AssociationInsert
    WHERE IsNewRecordMapping = 1
		AND (FP_DeviceID > 0 OR DeviceID > 0);
END$$

DELIMITER ;
