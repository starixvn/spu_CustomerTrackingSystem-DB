DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_RobotClassification_Insert`$$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_RobotClassification_Insert`(
	IN 	ip_DailyPrediction 		JSON,
    
    OUT op_ErrorMessage 		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210701@Long.Luu
		Task:		Insert Robot CLassification [Redmine ID: #0000]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20210217@Long.Luu: Created [Redmine ID: #0000]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotClassification_Insert ('[{"C": 111, "CID": 1, "IP": 1, "IPW": 1, "FD": "2021-07-01", "TD": "2021-07-15"}]', @ErrorMessage);    
	*/ 
    
    
    DECLARE CONST_ROBOTTYPE_OBSERVED 	TINYINT UNSIGNED DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT UNSIGNED DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT UNSIGNED DEFAULT 2;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ComboMapping;    
	CREATE TEMPORARY TABLE Temp_ComboMapping(	  	
			ComboID				SMALLINT UNSIGNED PRIMARY KEY
		, 	SportTypeID			SMALLINT UNSIGNED
		, 	BetTypeID			SMALLINT UNSIGNED
		, 	LiveIndicator		BIT       
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestInsertedClassification;    
	CREATE TEMPORARY TABLE Temp_LatestInsertedClassification(	  	
			CustID				BIGINT UNSIGNED
		, 	SportTypeID			SMALLINT UNSIGNED
		, 	BetTypeID			SMALLINT UNSIGNED
		, 	LiveIndicator		BIT     
        ,	FromDate			DATE
        ,	PRIMARY KEY 		PK_Temp_LatestInsertedClassification(CustID,SportTypeID,BetTypeID,LiveIndicator)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotClassification;    
	CREATE TEMPORARY TABLE Temp_RobotClassification(	  	
			CustID				BIGINT UNSIGNED
		, 	SportTypeID			SMALLINT UNSIGNED
		, 	BetTypeID			SMALLINT UNSIGNED
		, 	LiveIndicator		BIT       
        ,	RobotType			TINYINT
        ,	FromDate			DATE
        ,	ToDate				DATE    
        ,	PRIMARY KEY 		PK_Temp_RobotClassification(CustID,SportTypeID,BetTypeID,LiveIndicator)
	); 
    
    INSERT INTO Temp_ComboMapping(ComboID,SportTypeID,BetTypeID,LiveIndicator)
    VALUES (1,1,1,1),(2,1,1,0),(3,1,3,1),(4,1,3,0),(5,1,7,1),(6,1,7,0),(7,1,8,1),(8,1,8,0),(9,2,1,1),(10,2,1,0),(11,2,3,1),(12,2,3,0),(13,2,7,1),(14,2,7,0),(15,2,8,1),(16,2,8,0),(17,0,1,1),(18,0,1,0),(19,0,3,1),(20,0,3,0),(21,0,7,1),(22,0,7,0),(23,0,8,1),(24,0,8,0);
	
    INSERT INTO Temp_RobotClassification(CustID,SportTypeID,BetTypeID,LiveIndicator,RobotType,FromDate,ToDate)
	SELECT 	tmpTable.CustID
		, 	t.SportTypeID
		, 	t.BetTypeID
		, 	t.LiveIndicator
        ,	CASE 
				WHEN IsPrediction = 0 THEN CONST_ROBOTTYPE_OBSERVED 
                ELSE 
					CASE WHEN IsPredictWin = 0 THEN CONST_ROBOTTYPE_GOOD
                    ELSE CONST_ROBOTTYPE_BAD
				END 
			END AS RobotType
		,	tmpTable.FromDate
		,	tmpTable.ToDate
	FROM JSON_TABLE(ip_DailyPrediction,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.C"
            , ComboID 			TINYINT UNSIGNED	PATH "$.CID"
			, IsPrediction		BIT					PATH "$.IP"            
			, IsPredictWin		BIT					PATH "$.IPW"          
			, FromDate			DATE				PATH "$.FD"          
			, ToDate			DATE				PATH "$.TD"
		 )) AS tmpTable
         INNER JOIN Temp_ComboMapping AS t ON tmpTable.ComboID = t.ComboID;  
	
    INSERT INTO Temp_LatestInsertedClassification(CustID,SportTypeID,BetTypeID,LiveIndicator,FromDate)
    SELECT t.CustID, t.SportTypeID, t.BetTypeID, t.LiveIndicator, MAX(t.FromDate)
    FROM CTS_DataCenter.RobotClassification AS t
		INNER JOIN Temp_RobotClassification AS d ON t.CustID = d.CustID AND t.SportTypeID = d.SportTypeID
			AND t.BetTypeID = d.BetTypeID AND t.LiveIndicator = d.LiveIndicator
	GROUP BY t.CustID, t.SportTypeID, t.BetTypeID, t.LiveIndicator;
            
	DELETE d
	FROM Temp_LatestInsertedClassification AS t
		INNER JOIN Temp_RobotClassification AS d ON t.CustID = d.CustID AND t.SportTypeID = d.SportTypeID
			AND t.BetTypeID = d.BetTypeID AND t.LiveIndicator = d.LiveIndicator
    WHERE DATE_ADD(t.FromDate, INTERVAL 14 DAY) > d.FromDate;
            
	INSERT INTO CTS_DataCenter.RobotClassification(CustID,SportTypeID,BetTypeID,LiveIndicator,RobotType,FromDate,ToDate)
	SELECT CustID,SportTypeID,BetTypeID,LiveIndicator,RobotType,FromDate,ToDate
    FROM Temp_RobotClassification;
     
END$$	
DELIMITER ;