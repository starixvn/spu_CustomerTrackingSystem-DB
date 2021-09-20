DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_RobotDetection_Insert`$$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_RobotDetection_Insert`(
	IN 	ip_RobotInfo	 		JSON,
    
    OUT op_ErrorMessage 		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210922@Long.Luu
		Task:		Insert Robot Detection [Redmine ID: #0000]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20210217@Long.Luu: Created [Redmine ID: #0000]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotDetection_Insert ('[{"C": 111, "R": 1, "LR": 1}]', @ErrorMessage);    
	*/ 
    
    
    DECLARE lv_CurrentDateTime 			DATETIME DEFAULT NOW();
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotInfo;    
	CREATE TEMPORARY TABLE Temp_RobotInfo(	  	
			CustID						BIGINT UNSIGNED
		, 	PeriodRangeType				SMALLINT UNSIGNED
        ,	LatestPeriodRangeType		SMALLINT UNSIGNED
		,	IsNewRobot					BIT DEFAULT 1
        ,	PRIMARY KEY 				PK_Temp_RobotInfo(CustID)
	); 
    
    INSERT INTO Temp_RobotInfo(CustID, PeriodRangeType, LatestPeriodRangeType)
	SELECT 	tmpTable.CustID
		, 	tmpTable.PeriodRangeType
        ,	tmpTable.LatestPeriodRangeType
	FROM JSON_TABLE(ip_RobotInfo,
		 "$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.C"
            , 	PeriodRangeType 		SMALLINT UNSIGNED	PATH "$.R"
            , 	LatestPeriodRangeType 	SMALLINT UNSIGNED	PATH "$.LR"
		 )) AS tmpTable;  
	
    UPDATE Temp_RobotInfo AS t
		LEFT JOIN CTS_DataCenter.RobotDetection AS a ON t.CustID = a.CustID
	SET t.IsNewRobot = 0
    WHERE a.CustID IS NOT NULL
		AND t.CustID IS NOT NULL;
    
    INSERT INTO CTS_DataCenter.RobotDetection(CustID,PeriodRangeType, LatestPeriodRangeType,CreatedDate,LastModifiedDate)
    SELECT CustID, PeriodRangeType, LatestPeriodRangeType, lv_CurrentDateTime, lv_CurrentDateTime
    FROM Temp_RobotInfo
	WHERE IsNewRobot = 1;
            
	UPDATE CTS_DataCenter.RobotDetection AS a
		INNER JOIN Temp_RobotInfo AS t ON t.CustID = a.CustID
    SET 	a.PeriodRangeType = t.PeriodRangeType
		,	a.LatestPeriodRangeType = t.LatestPeriodRangeType
        ,	a.LastModifiedDate = lv_CurrentDateTime
    WHERE t.IsNewRobot = 0;
     
END$$	
DELIMITER ;