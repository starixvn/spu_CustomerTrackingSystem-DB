/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_Association_DeviceAssociationDay_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_DeviceAssociationDay_Insert`(
		IN ip_BatchSize INT
)
    SQL SECURITY INVOKER
sp:BEGIN
	/* 
		Created:	20210408@Aries.Nguyen
		Task:		Compress association day by device
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210326@Aries.Nguyen: Created [Redmine ID: #148998]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_DeviceAssociationDay_Insert(200);
	*/

    DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorMessage 	VARCHAR(200) DEFAULT '';
    DECLARE lv_ErrorMessage2 	VARCHAR(200) DEFAULT '';
    
    DECLARE lv_CTSAssDevID BIGINT UNSIGNED;
    DECLARE lv_CTSAssDevID_Next BIGINT UNSIGNED;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            lv_ErrorMessage 	= 	MESSAGE_TEXT;
		
        IF(lv_No > 1) THEN
				SET lv_No = lv_No - 1;
				GET STACKED  DIAGNOSTICS CONDITION lv_No
					lv_ErrorMessage2 = MESSAGE_TEXT;	
		END IF;
        
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(52, '', JSON_OBJECT('lv_CTSAssDevID',lv_CTSAssDevID,'lv_CTSAssDevID_Next',lv_CTSAssDevID_Next, 'ErrorMessage', CONCAT(lv_ErrorMessage,'; ',lv_ErrorMessage2 )));
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCust;
	CREATE TEMPORARY TABLE 		Temp_DeviceCust (
			DCSDeviceID			BIGINT UNSIGNED 
		,	CTSCustID 			BIGINT UNSIGNED
		,	Created				TIMESTAMP
		,	CreatedDays			INT AS (TO_DAYS(Created))
		,	IsExist				BIT DEFAULT 0
        
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID;
	CREATE TEMPORARY TABLE 		Temp_CTSCustID (
			CTSCustID			BIGINT UNSIGNED PRIMARY KEY
	);
   
   DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
   CREATE TEMPORARY TABLE 		Temp_CustAssociation (
			CTSCustID 			BIGINT UNSIGNED
		 ,	CTSCustID_Aff 		BIGINT UNSIGNED
		 ,	DCSDeviceID			BIGINT UNSIGNED
		 ,	AssociationDate		TIMESTAMP
		 ,	AssociationDay		INT AS (TO_DAYS(AssociationDate))
		 , 	PRIMARY KEY (CTSCustID,CTSCustID_Aff)
	);  

	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceAssociationDay;
	CREATE TEMPORARY TABLE 		Temp_DeviceAssociationDay (
			DCSDeviceID 			BIGINT UNSIGNED
		 ,	AssociationDay			INT
		 ,	IsExist					BIT DEFAULT 0
		 , 	PRIMARY KEY (DCSDeviceID,AssociationDay)
	); 

	DROP TEMPORARY TABLE IF EXISTS Temp_Device_Update;
	CREATE TEMPORARY TABLE 		Temp_Device_Update (
			DCSDeviceID 		BIGINT UNSIGNED
		, 	AssociationDay		JSON
		,	IsLargeDevice		BIT DEFAULT 0
        ,	RowOrder 			SMALLINT UNSIGNED DEFAULT 0
	); 
    
    SELECT IFNULL(CONVERT(ParameterValue, UNSIGNED),0)
    INTO lv_CTSAssDevID
    FROM  CTS_DataCenter.SystemParameter
    WHERE ParameterID = 16;
    
     WITH CTE_NewAccountDevice AS (
			SELECT CTSAssDevID
			FROM CTS_DataCenter.AssociationByDevice as asDe
			WHERE CTSAssDevID > lv_CTSAssDevID
			LIMIT ip_BatchSize
	)
	SELECT  MIN(CTSAssDevID), MAX(CTSAssDevID)
	INTO 	lv_CTSAssDevID, lv_CTSAssDevID_Next
	FROM CTE_NewAccountDevice;
    
    IF lv_CTSAssDevID IS NULL OR lv_CTSAssDevID_Next IS NULL THEN
		LEAVE sp;
	END IF;
    
    #Get Cust Has Association Device
	INSERT INTO Temp_DeviceCust(DCSDeviceID, CTSCustID, Created)
	SELECT 	DCSDeviceID
		, 	CTSCustID
		,	CreatedTime
	FROM CTS_DataCenter.AssociationByDevice as cuDv
	WHERE cuDv.CTSAssDevID BETWEEN lv_CTSAssDevID AND  lv_CTSAssDevID_Next
		AND EXISTS (SELECT 1 FROM  AssociationByDevice dv 
					WHERE cuDv.DCSDeviceID = dv.DCSDeviceID 
						AND dv.CTSCustID !=  cuDv.CTSCustID);
                        
	#Delete Device Days Exist
	DELETE FROM Temp_DeviceCust tmp
	WHERE  EXISTS(SELECT 1 
				  FROM  CTS_DataCenter.DeviceAssociationDay AS deAs
				  WHERE tmp.DCSDeviceID = deAs.DCSDeviceID 
					AND tmp.CreatedDays MEMBER OF(deAs.AssociationDay -> "$"));
                    
	INSERT INTO Temp_CTSCustID(CTSCustID)
	SELECT DISTINCT CTSCustID 
	FROM Temp_DeviceCust;
    
    INSERT INTO Temp_CustAssociation(CTSCustID, CTSCustID_Aff, DCSDeviceID,  AssociationDate)
	SELECT  temp.CTSCustID
		,	asCus.CTSCustID  
		,	asCus.DCSDeviceID
		,	GREATEST(asDv.CreatedTime, asCus.CreatedTime)
	FROM Temp_CTSCustID AS temp 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON temp.CTSCustID =  asDv.CTSCustID  
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asDv.DCSDeviceID =  asCus.DCSDeviceID  AND temp.CTSCustID  !=   asCus.CTSCustID 
	ON DUPLICATE KEY UPDATE AssociationDate = LEAST(Temp_CustAssociation.AssociationDate, GREATEST(asDv.CreatedTime, asCus.CreatedTime))
						,	DCSDeviceID = CASE WHEN Temp_CustAssociation.AssociationDate < GREATEST(asDv.CreatedTime, asCus.CreatedTime) THEN  Temp_CustAssociation.DCSDeviceID
										  ELSE asCus.DCSDeviceID END; 
    
    INSERT IGNORE Temp_DeviceAssociationDay(DCSDeviceID, AssociationDay)
	SELECT 	DISTINCT DCSDeviceID
		,	AssociationDay
	FROM Temp_CustAssociation;
    
	DELETE FROM Temp_DeviceAssociationDay AS temp
	WHERE EXISTS (SELECT 1 
					  FROM CTS_DataCenter.DeviceAssociationDay AS dvDa 
					  WHERE dvDa.DCSDeviceID = temp.DCSDeviceID AND  temp.AssociationDay MEMBER OF(dvDa.AssociationDay -> "$") );										

	UPDATE Temp_DeviceAssociationDay AS temp
	SET IsExist = 1
	WHERE EXISTS (SELECT 1 
				  FROM CTS_DataCenter.DeviceAssociationDay AS dvDa 
				  WHERE dvDa.DCSDeviceID = temp.DCSDeviceID);

	INSERT INTO CTS_DataCenter.DeviceAssociationDay(DCSDeviceID, AssociationDay)
	SELECT DCSDeviceID, JSON_ARRAYAGG(AssociationDay) 
	FROM Temp_DeviceAssociationDay
	WHERE IsExist = 0
	GROUP BY DCSDeviceID;


	INSERT INTO Temp_Device_Update(DCSDeviceID, AssociationDay)
	SELECT 		DCSDeviceID
			, 	JSON_ARRAYAGG(AssociationDay) AS AssociationDay
	FROM Temp_DeviceAssociationDay
	WHERE IsExist = 1
	GROUP BY DCSDeviceID;

	UPDATE Temp_Device_Update temp
	INNER JOIN CTS_DataCenter.DeviceAssociationDay AS dvDa ON dvDa.DCSDeviceID = temp.DCSDeviceID AND dvDa.IsMaxDeviceStorage = 0
	SET temp.IsLargeDevice = CASE WHEN JSON_LENGTH(dvDa.AssociationDay) >  100 THEN 1 ELSE 0 END,
		temp.RowOrder = dvDa.RowOrder + 1;

	UPDATE CTS_DataCenter.DeviceAssociationDay AS dvDa
	INNER JOIN Temp_Device_Update temp  ON dvDa.DCSDeviceID = temp.DCSDeviceID AND temp.IsLargeDevice = 1
	SET IsMaxDeviceStorage = 1;

	INSERT INTO CTS_DataCenter.DeviceAssociationDay(DCSDeviceID, AssociationDay, RowOrder)
	SELECT 	DCSDeviceID
		,	AssociationDay
        ,	RowOrder
	FROM Temp_Device_Update AS temp
	WHERE temp.IsLargeDevice = 1;

	UPDATE CTS_DataCenter.DeviceAssociationDay  AS dvDa 
	INNER JOIN	Temp_Device_Update  AS tmp ON   dvDa.DCSDeviceID = tmp.DCSDeviceID 
												AND dvDa.IsMaxDeviceStorage = 0 
												AND tmp.IsLargeDevice = 0
	SET dvDa.AssociationDay = JSON_MERGE_PRESERVE(dvDa.AssociationDay, tmp.AssociationDay);

	UPDATE CTS_DataCenter.SystemParameter 
	SET ParameterValue = lv_CTSAssDevID_Next
	WHERE ParameterID = 16;
        
END$$

DELIMITER ;