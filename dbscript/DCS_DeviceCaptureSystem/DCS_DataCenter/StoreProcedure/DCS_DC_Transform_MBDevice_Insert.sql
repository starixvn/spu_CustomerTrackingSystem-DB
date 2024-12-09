/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDevice_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDevice_Insert`(
    IN ip_MBTransactionInfoJson LONGTEXT
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
			SET sql_safe_updates = 0;
			CALL DCS_DC_Transform_MBDevice_Insert('1,2,3,4,5');
	*/

	DECLARE vrDeviceStatusNew			TINYINT DEFAULT 1;			# New Device
	DECLARE vrDeviceStatusOld			TINYINT DEFAULT 2;			# Old Device
	DECLARE vrDeviceStatusRecover		TINYINT DEFAULT 3;			# Recover Device
	
    DECLARE lv_AssociationJson 			LONGTEXT;
    DECLARE lv_NewAccountDeviceJson 	LONGTEXT;
    
    DECLARE lv_InsertionTime 			TIMESTAMP(4) DEFAULT CURRENT_TIMESTAMP(4);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceMappingInfo;
	CREATE TEMPORARY TABLE Temp_DeviceMappingInfo(
			TransID						BIGINT UNSIGNED NOT NULL PRIMARY KEY 
		,	MBRawTransactionID			BIGINT UNSIGNED
		,	MBAccountID					BIGINT UNSIGNED
		,	SubscriberID				BIGINT UNSIGNED

		,	MBDeviceCodeMediaDRMID		BIGINT UNSIGNED
		,	MBDeviceCodeMachineID		BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID		BIGINT UNSIGNED
		,	SameDeviceWithRawTransID	BIGINT UNSIGNED DEFAULT 0
		,	RecoverType					SMALLINT UNSIGNED DEFAULT 0
		
		,	MBDeviceMappingID			BIGINT UNSIGNED
		,	MBDeviceID					BIGINT UNSIGNED
	);

	#========GET INPUT DATA===========================        
    INSERT INTO Temp_DeviceMappingInfo(TransID, MBRawTransactionID, MBAccountID, SubscriberID, SameDeviceWithRawTransID, RecoverType, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
	SELECT 	tmp.TransID
		,	trans.MBRawTransactionID
		,	trans.MBAccountID
		,	trans.SubscriberID
		,	tmp.SameDeviceWithRawTransID
		,	tmp.RecoverType
		,	tmp.MBDeviceCodeMediaDRMID
		,	tmp.MBDeviceCodeMachineID
		,	tmp.MBDeviceCodeTaggingID
    FROM JSON_TABLE(
			ip_MBTransactionInfoJson,
			 "$[*]" COLUMNS(
							TransID						BIGINT UNSIGNED		PATH "$.TransID"
						,	SameDeviceWithRawTransID	BIGINT UNSIGNED 	PATH "$.SameDeviceWithRawTransID"
						,	RecoverType					SMALLINT UNSIGNED 	PATH "$.MBAccountID"
						,	MBDeviceCodeMediaDRMID		BIGINT UNSIGNED 	PATH "$.MBDeviceCodeMediaDRMID"
						,	MBDeviceCodeMachineID		BIGINT UNSIGNED 	PATH "$.MBDeviceCodeMachineID"
						,	MBDeviceCodeTaggingID		BIGINT UNSIGNED 	PATH "$.MBDeviceCodeTaggingID"
					)
		) AS tmp
		INNER JOIN DCS_DataCenter.MBTransaction AS trans ON trans.ID = tmp.TransID;
    
    select * from Temp_DeviceMappingInfo;
	CALL DCS_DC_Transform_MBDeviceMapping_Insert('Temp_DeviceMappingInfo');
    
    select * from Temp_DeviceMappingInfo;
    /* === Insert new Association === */
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				MBAccountID
			,	MBDeviceID
			,	SubscriberID
		FROM Temp_DeviceMappingInfo
		WHERE MBAccountID > 0
			AND MBDeviceID > 0
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'MBAccountID'	, MBAccountID
				,	'MBDeviceID'	, MBDeviceID
				,	'SubscriberID'	, SubscriberID
			)
		) AS json_data
	INTO lv_AssociationJson
	FROM cte_DistinctData;
    
    select lv_AssociationJson;
    IF lv_AssociationJson IS NOT NULL THEN
		CALL DCS_DC_Transform_MBAssociation_Insert(lv_AssociationJson);
    END IF;
    
	INSERT IGNORE INTO DCS_DataCenter.MBTransaction07(CreatedDate, MBRawTransactionID, TransTime, SubscriberID, MBAccountID, IP, IPID, ActionResultID, Flagged, MBDeviceModelID, MBOSID, MBUserSettingID, MBDeviceMappingID, MBDeviceID, RecoverType, InsertedTime)
	SELECT	DATE(trans.TransTime) AS CreatedDate
		,	trans.MBRawTransactionID
        ,	trans.TransTime
        ,	trans.SubscriberID
        , 	trans.MBAccountID
        ,	trans.IP
        ,	trans.IPID
        ,	trans.ActionResultID
        ,	trans.Flagged
        ,	trans.MBDeviceModelID
        ,	trans.MBOSID
        ,	trans.MBUserSettingID
        ,	IFNULL(tmp.MBDeviceMappingID,0) AS MBDeviceMappingID
        ,	IFNULL(tmp.MBDeviceID,0) AS MBDeviceID
        ,	IFNULL(tmp.RecoverType,0) AS RecoverType
        ,	lv_InsertionTime AS InsertedTime
	FROM Temp_DeviceMappingInfo AS tmp
		INNER JOIN DCS_DataCenter.MBTransaction AS trans ON trans.ID = tmp.TransID;
    
	DELETE trans
	FROM DCS_DataCenter.MBTransaction AS trans
		INNER JOIN Temp_DeviceMappingInfo AS tmp ON tmp.TransID = trans.ID;
    
END$$

DELIMITER ;