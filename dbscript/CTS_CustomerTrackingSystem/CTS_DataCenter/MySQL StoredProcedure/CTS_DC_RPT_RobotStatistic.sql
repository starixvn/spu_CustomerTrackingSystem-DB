/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_RobotStatistic`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_RobotStatistic`(
		IN	ip_IsMonthly		BOOLEAN
	,	IN	ip_IsDaily			BOOLEAN
	,	IN	ip_FromDate			DATETIME
	,	IN	ip_ToDate			DATETIME
	,	IN	ip_CustCounterJs 	JSON 
)
    SQL SECURITY INVOKER
sp:BEGIN
	/* 
		Created:	20230915@Casey.Huynh
		Task:		Robot Statistic Report
		DB:			CTS_DataCenter
        
		Revisions:
			- 20230915@Casey.Huynh: Created [Redmine ID: #193036]

		Param's Explanation (filtered by):

        Example:
			CALL CTS_DC_RPT_RobotStatistic(@ip_IsMontly:=1, @ip_IsDaily:=1, @ip_FromDate:='2023-03-24', @ip_ToDate:='2023-05-18'
            , @ip_CustCounterJs:='[]' );
	*/
    DECLARE CONST_ROBOTTYPE_AI		SMALLINT DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_IMPERVA	SMALLINT DEFAULT 2;
    DECLARE CONST_ROBOTTYPE_COUNTER	SMALLINT DEFAULT 3;
    
    #==========================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_CustRobot;
	CREATE TEMPORARY TABLE 		Temp_CustRobot (
			CustID		BIGINT UNSIGNED
		,	RobotType	SMALLINT
		,	RobotDate	DATETIME
        ,	RobotMonth	VARCHAR(7)	       
        
        ,	PRIMARY KEY PK_Temp_CustRobot_RobotTypeCustID(RobotType, CustID)
        ,	INDEX IX_Temp_CustRobot_RobotDateRobotTypeCustID(RobotDate, RobotType, CustID)
        ,	INDEX IX_Temp_CustRobot_RobotMonthRobotTypeCustID(RobotMonth, RobotType, CustID)
	);   
	
	#======================INSERT ROBOT AI=========================================================
	INSERT IGNORE INTO Temp_CustRobot(CustID, RobotType, RobotDate, RobotMonth)
	SELECT	rd.CustID
		,	CONST_ROBOTTYPE_AI AS RobotType
		,	rd.CreatedDate AS RobotDate
		,	DATE_FORMAT(rd.CreatedDate, '%Y/%m') AS RobotMonth
	FROM CTS_DataCenter.RobotDetection AS rd
    ORDER BY rd.ID ASC;
    
    #======================INSERT ROBOT IMPERVA=========================================================
	INSERT IGNORE INTO Temp_CustRobot(CustID, RobotType, RobotDate, RobotMonth)
	SELECT	ri.CustID
		,	CONST_ROBOTTYPE_IMPERVA AS RobotType
		,	DATE(ri.CreateTime) AS RobotDate
		,	DATE_FORMAT(ri.CreateTime, '%Y/%m') AS RobotMonth
	FROM CTS_DataCenter.RobotImperva AS ri
    ORDER BY ri.LogID ASC;
    
    #======================INSERT ROBOT COUNTER=========================================================
    IF ip_CustCounterJs <> '' THEN
		INSERT IGNORE INTO Temp_CustRobot(CustID, RobotType, RobotDate, RobotMonth)
		SELECT  js.CustID
			,	CONST_ROBOTTYPE_COUNTER AS RobotType
			,	js.RobotDate
            ,	DATE_FORMAT(js.RobotDate, '%Y/%m') AS RobotMonth
		FROM JSON_TABLE(ip_CustCounterJs,
					 "$[*]" COLUMNS(
								CustID		BIGINT UNSIGNED PATH "$.CustID" 	
							,	RobotDate	DATETIME PATH "$.RobotDate" 
						)
					) AS js;  
    END IF;
	
    #======================RETURN DATA===============================================================
   
    IF ip_IsMonthly = 1 THEN
		SELECT 	tmpCr.RobotMonth AS 'Month'
			,	SUM(CASE WHEN tmpCr.RobotType = 1 THEN 1 ELSE 0 END) AS AI
            ,	SUM(CASE WHEN tmpCr.RobotType = 2 THEN 1 ELSE 0 END) AS IMPERVA
            ,	SUM(CASE WHEN tmpCr.RobotType = 3 THEN 1 ELSE 0 END) AS COUNTER
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByDate
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.RobotMonth;     

		SELECT	tmpCr.RobotType
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByRobotType
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.RobotType;  

    END IF;
    
	IF ip_IsDaily = 1 THEN
		SELECT DATE(tmpCr.RobotDate) AS 'Date'
			,	SUM(CASE WHEN tmpCr.RobotType = 1 THEN 1 ELSE 0 END) AS AI
            ,	SUM(CASE WHEN tmpCr.RobotType = 2 THEN 1 ELSE 0 END) AS IMPERVA
            ,	SUM(CASE WHEN tmpCr.RobotType = 3 THEN 1 ELSE 0 END) AS COUNTER
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByDate
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.RobotDate;     
        
		SELECT	tmpCr.RobotType
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByRobotType
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.RobotType;  
    END IF;
    
END$$

DELIMITER ;
