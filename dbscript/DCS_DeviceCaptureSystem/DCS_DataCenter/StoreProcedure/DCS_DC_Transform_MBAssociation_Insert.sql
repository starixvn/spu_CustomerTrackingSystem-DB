/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBAssociation_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBAssociation_Insert`(
	IN ip_AssociationJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20241205@Jonathan.Doan
	    Task : Transform Device to Transaction07
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
		    - 20241205@Jonathan.Doan: Created [RedmineID: #213401]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_MBAssociation_Insert('[{"MBDeviceID": 101, "MBAccountID": 3, "SubscriberID": 2}, {"MBDeviceID": 102, "MBAccountID": 3, "SubscriberID": 2}]');
			select * from MBAssociation;
	*/
    DECLARE lv_InsertedTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_MBAssociationInsert;
        
	CREATE TEMPORARY TABLE Temp_MBAssociationInsert(
			ID					INT UNSIGNED		NOT NULL AUTO_INCREMENT PRIMARY KEY
        ,	MBAccountID			BIGINT UNSIGNED		NOT NULL
        ,	MBDeviceID			BIGINT UNSIGNED		DEFAULT 0
        ,	SubscriberID		BIGINT UNSIGNED		
		,	IsNewRecord			TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_MBAssociationInsert(MBAccountID, MBDeviceID, SubscriberID)
	SELECT 	tmp.MBAccountID
		,	tmp.MBDeviceID
		,	MIN(tmp.SubscriberID) AS SubscriberID
    FROM JSON_TABLE(
			ip_AssociationJson,
			 "$[*]" COLUMNS(
							MBAccountID			BIGINT UNSIGNED	PATH "$.MBAccountID"
						,	MBDeviceID			BIGINT UNSIGNED PATH "$.MBDeviceID"
						,	SubscriberID		INT 			PATH "$.SubscriberID"
					)
		) AS tmp
	WHERE tmp.MBAccountID > 0
		AND tmp.MBDeviceID > 0
	GROUP BY tmp.MBAccountID, tmp.MBDeviceID;
    
    UPDATE Temp_MBAssociationInsert AS tmp
		INNER JOIN DCS_DataCenter.MBAssociation AS ass ON ass.MBAccountID = tmp.MBAccountID
													AND ass.MBDeviceID = tmp.MBDeviceID
    SET tmp.IsNewRecord = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.MBAssociation(MBAccountID, MBDeviceID, SubscriberID, InsertedTime)
	SELECT	MBAccountID
		,	MBDeviceID
		,	SubscriberID
		,	lv_InsertedTime AS InsertedTime
	FROM Temp_MBAssociationInsert
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;