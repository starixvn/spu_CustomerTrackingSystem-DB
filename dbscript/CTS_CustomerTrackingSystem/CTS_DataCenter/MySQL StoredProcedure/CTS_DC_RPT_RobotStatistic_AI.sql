/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="1"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_RobotStatistic_AI`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_RobotStatistic_AI`(
		IN	ip_IsMonthly		BOOLEAN
	,	IN	ip_IsDaily			BOOLEAN
	,	IN	ip_FromDate			DATETIME
	,	IN	ip_ToDate			DATETIME
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
			CALL CTS_DC_RPT_RobotStatistic_AI(@ip_IsMontly:=1, @ip_IsDaily:=1, @ip_FromDate:='2023-03-24', @ip_ToDate:='2023-05-18');
	*/
    DECLARE CONST_ROBOTAI_TI	SMALLINT DEFAULT 1;
    DECLARE CONST_ROBOTAI_SCE	SMALLINT DEFAULT 2;
	DECLARE CONST_ROBOTAI_TD	SMALLINT DEFAULT 3;
    DECLARE CONST_ROBOTAI_OCRD	SMALLINT DEFAULT 4;
    
    #==========================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_CustRobot;
	CREATE TEMPORARY TABLE 		Temp_CustRobot (
			CustID		BIGINT UNSIGNED
		,	AIType		SMALLINT
		,	RobotDate	DATETIME
        ,	RobotMonth	VARCHAR(7)	       
        
        ,	PRIMARY KEY PK_Temp_CustRobot_AITypeCustID(AIType, CustID)
        ,	INDEX IX_Temp_CustRobot_RobotDateAITypeCustID(RobotDate, AIType, CustID)
        ,	INDEX IX_Temp_CustRobot_RobotMonthAITypeCustID(RobotMonth, AIType, CustID)
	);   
	
	#======================INSERT ROBOT AI=========================================================
	INSERT IGNORE INTO Temp_CustRobot(CustID, AIType, RobotDate, RobotMonth)
	SELECT	rd.CustID
		,	(CASE WHEN rd.PeriodRangeType BETWEEN 1 AND 99 THEN CONST_ROBOTAI_TI
				WHEN rd.PeriodRangeType BETWEEN 101 AND 199 THEN CONST_ROBOTAI_SCE
                WHEN rd.PeriodRangeType BETWEEN 200 AND 299 THEN CONST_ROBOTAI_OCRD
                WHEN rd.PeriodRangeType BETWEEN 300 AND 399 THEN CONST_ROBOTAI_TD
			END) AS AIType
		,	rd.CreatedDate AS RobotDate
		,	DATE_FORMAT(rd.CreatedDate, '%Y/%m') AS RobotMonth
	FROM CTS_DataCenter.RobotDetection AS rd
    ORDER BY rd.ID ASC;

    #======================RETURN DATA===============================================================
   
    IF ip_IsMonthly = 1 THEN
		SELECT 	tmpCr.RobotMonth AS 'Month'
			,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_TI THEN 1 ELSE 0 END) AS TI
            ,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_SCE THEN 1 ELSE 0 END) AS SCE
            ,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_OCRD THEN 1 ELSE 0 END) AS OCRD
            ,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_TD THEN 1 ELSE 0 END) AS TD
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByMonth
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.RobotMonth;     

		SELECT	tmpCr.AIType
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByAIType
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.AIType;  

    END IF;
    
	IF ip_IsDaily = 1 THEN
		SELECT DATE(tmpCr.RobotDate) AS 'Date'
			,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_TI THEN 1 ELSE 0 END) AS TI
            ,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_SCE THEN 1 ELSE 0 END) AS SCE
            ,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_OCRD THEN 1 ELSE 0 END) AS OCRD
            ,	SUM(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_TD THEN 1 ELSE 0 END) AS TD
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByDate
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.RobotDate;     
        
		SELECT	(CASE WHEN tmpCr.AIType = CONST_ROBOTAI_TI THEN TI
					WHEN tmpCr.AIType = CONST_ROBOTAI_SCE THEN SCE
                    WHEN tmpCr.AIType = CONST_ROBOTAI_OCRD THEN OCRD
                    WHEN tmpCr.AIType = CONST_ROBOTAI_TD THEN TD
				END
				) AS AIType
            ,	COUNT(DISTINCT tmpCr.CustID) AS TotalAccountByAIType
        FROM Temp_CustRobot AS tmpCr
        GROUP BY tmpCr.AIType;  
    END IF;
    
END$$

DELIMITER ;
