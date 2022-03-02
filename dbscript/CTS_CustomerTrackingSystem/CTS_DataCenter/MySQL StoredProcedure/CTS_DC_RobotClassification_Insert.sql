DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_RobotClassification_Insert`$$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_RobotClassification_Insert`(
	IN 	ip_DailyPrediction 		JSON,
    IN 	ip_TestingLength		INT,
	
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
			- 20220210@Diego.Nguyen: Created [Redmine ID: #0000]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotClassification_Insert ('[{"C": 222, "IP": 1, "IPW": 1, "FD": "2021-07-01", "TD": "2021-07-15", "WL": 3000, "AD":22, "BC":33, "TO":5000}]', @ErrorMessage);    call CTS_DataCenter.CTS_DC_RobotClassification_Insert ('[{"C": 111, "CID": 1, "IP": 1, "IPW": 1, "FD": "2021-07-01", "TD": "2021-07-15"}]', @ErrorMessage);    
	*/ 
    
    DECLARE CONST_ROBOTTYPE_OBSERVED 	TINYINT UNSIGNED DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT UNSIGNED DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT UNSIGNED DEFAULT 2;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestInsertedClassification;    
	CREATE TEMPORARY TABLE Temp_LatestInsertedClassification(	  	
			CustID				BIGINT UNSIGNED
        ,	FromDate			DATE
        ,	PRIMARY KEY 		PK_Temp_LatestInsertedClassification(CustID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotClassification;    
	CREATE TEMPORARY TABLE Temp_RobotClassification(	  	
			CustID				BIGINT UNSIGNED
        ,	RobotType			TINYINT
        ,	FromDate			DATE
        ,	ToDate				DATE
        , 	Winloss				DECIMAL(20,4)		
		, 	ActiveDays			TINYINT					
		, 	BetCount			INT					
		, 	Turnover			DECIMAL(20,4)
        ,	PRIMARY KEY 		PK_Temp_RobotClassification(CustID,FromDate)
	); 
	
    INSERT INTO Temp_RobotClassification(CustID,RobotType,FromDate,ToDate,Winloss,ActiveDays,BetCount,Turnover)
	SELECT 	tmpTable.CustID
        ,	CASE 
				WHEN IsPrediction = 0 THEN CONST_ROBOTTYPE_OBSERVED 
                ELSE 
					CASE WHEN IsPredictWin = 0 THEN CONST_ROBOTTYPE_GOOD
                    ELSE CONST_ROBOTTYPE_BAD
				END 
			END AS RobotType
		,	tmpTable.FromDate
		,	tmpTable.ToDate
        ,	tmpTable.Winloss
        ,	tmpTable.ActiveDays
        ,	tmpTable.BetCount
        ,	tmpTable.Turnover
	FROM JSON_TABLE(ip_DailyPrediction,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.C"
            /*, ComboID 			TINYINT UNSIGNED	PATH "$.CID"*/
			, IsPrediction		BIT					PATH "$.IP"            
			, IsPredictWin		BIT					PATH "$.IPW"          
			, FromDate			DATE				PATH "$.FD"          
			, ToDate			DATE				PATH "$.TD"
            , Winloss			DECIMAL(20,4)		PATH "$.WL"
            , ActiveDays		INT					PATH "$.AD"
            , BetCount			INT					PATH "$.BC"
            , Turnover			DECIMAL(20,4)		PATH "$.TO"
		 )) AS tmpTable;  
	
    INSERT INTO Temp_LatestInsertedClassification(CustID,FromDate)
    SELECT t.CustID, MAX(t.FromDate)
    FROM CTS_DataCenter.RobotClassification AS t
		INNER JOIN Temp_RobotClassification AS d ON t.CustID = d.CustID
	GROUP BY t.CustID;
            
	DELETE d
	FROM Temp_LatestInsertedClassification AS t
		INNER JOIN Temp_RobotClassification AS d ON t.CustID = d.CustID
    WHERE DATE_ADD(t.FromDate, INTERVAL ip_TestingLength DAY) > d.FromDate;
            
	INSERT INTO CTS_DataCenter.RobotClassification(CustID,RobotType,FromDate,ToDate,Winloss,ActiveDays,BetCount,Turnover)
	SELECT CustID,RobotType,FromDate,ToDate,Winloss,ActiveDays,BetCount,Turnover
    FROM Temp_RobotClassification;
     
END$$	
DELIMITER ;