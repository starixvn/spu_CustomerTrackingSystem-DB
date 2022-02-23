/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotClassification_GetRobotStatusByTransList`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotClassification_GetRobotStatusByTransList`(
		IN ip_TransList JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210818@Harvey.Nguyen
		Task:		Get lastest robot classification
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210818@Harvey.Nguyen: Created [Redmine ID: #160382]
			- 20210907@Long.Luu: Update Robot Users rules  [Redmine ID: #161232]
			- 20220214@Long.Luu: Support new category for Good & Bad Robot User [Redmine ID: #167726]
            
		Explanation:
			- RobotType: 2-Bad | 1-Good | 0-Observed | -1-No classification | -2-Not Robot
            
        Example:
            CALL CTS_DC_RobotClassification_GetRobotStatusByTransList('[
						{"CustID":23264137, "TransDate": "2021-11-11", "TransID":"1"}
					,	{"CustID":23264137, "TransDate": "2021-11-24", "TransID":"2"}
					,	{"CustID":23264137, "TransDate": "2021-12-11", "TransID":"3"}
					,	{"CustID":23264137, "TransDate": "2022-12-14", "TransID":"4"}
					,	{"CustID":23264138, "TransDate": "2022-12-14", "TransID":"5"}
					]');

	*/    
    DECLARE CONST_ROBOTTYPE_NOTROBOT 	TINYINT DEFAULT -2;
    DECLARE CONST_ROBOTTYPE_ROBOT 		TINYINT DEFAULT -1;
    DECLARE CONST_ROBOTTYPE_OBSERVED	TINYINT DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT DEFAULT 2;
    DECLARE CONST_CATEGORY_ROBOT 		SMALLINT DEFAULT 61;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			CustID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        ,	TransID		BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_Trans(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotClassificationHistory;
    CREATE TEMPORARY TABLE Temp_RobotClassificationHistory(
			CustID				BIGINT UNSIGNED
		,	TransDate			DATETIME(3)
        ,	TransID				BIGINT UNSIGNED
        ,	RobotType			SMALLINT
        ,	LastModifiedDate	DATETIME
        
        ,	PRIMARY KEY PK_Temp_TransRobot(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistsRobotClassification;
    CREATE TEMPORARY TABLE Temp_ExistsRobotClassification(
			CustID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        ,	TransID		BIGINT UNSIGNED
        ,	Priority	TINYINT
        
        ,	PRIMARY KEY PK_Temp_ExistsRobotClassification(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransLatestRobotClassificationDate;  
	CREATE TEMPORARY TABLE Temp_TransLatestRobotClassificationDate
    (
			TransID			BIGINT UNSIGNED
        ,	ScannedDate		DATETIME
    );
    
    /* START */    
    INSERT INTO Temp_Trans(CustID,TransDate,TransID)
	SELECT  js.CustID
		,	js.TransDate
		,	js.TransID
	FROM JSON_TABLE(ip_TransList,
		"$[*]" COLUMNS(
				CustID			BIGINT UNSIGNED PATH "$.CustID" 
			,	TransDate		DATETIME(3) PATH "$.TransDate"                               
			,	TransID			BIGINT UNSIGNED PATH "$.TransID"
		)) AS js;    
            
    INSERT INTO Temp_RobotClassificationHistory(CustID, TransDate, TransID, RobotType, LastModifiedDate)    
    SELECT	t.CustID
		,	t.TransDate
		,	t.TransID
		,	w.RobotType
        ,	w.FromDate
    FROM Temp_Trans AS t,
        LATERAL(
			SELECT RobotType, FromDate
			FROM RobotClassification
			WHERE CustID = t.CustID
				AND FromDate <= t.TransDate
			ORDER BY FromDate DESC
			LIMIT 1
		) AS w;
    
    INSERT INTO Temp_TransLatestRobotClassificationDate(TransID, ScannedDate)
    SELECT	TransID
		,	MAX(LastModifiedDate)
	FROM Temp_RobotClassificationHistory
	GROUP BY TransID;
    
    WITH CTE_temp (TransID, RobotType, IsAIRobot, IsTWRobot) AS
    (
		SELECT 	h.TransID
			,	(	CASE	
						WHEN h.RobotType IN (CONST_ROBOTTYPE_GOOD,CONST_ROBOTTYPE_BAD,CONST_ROBOTTYPE_OBSERVED) THEN h.RobotType
						ELSE CONST_ROBOTTYPE_ROBOT
					END
				) AS RobotType
			,	EXISTS (SELECT 1 FROM RobotDetection AS r WHERE r.CustID = h.CustID AND r.CreatedDate < h.TransDate) AS IsAIRobot
            ,	EXISTS (SELECT 1 FROM CTSCustomerClassification AS c WHERE c.CustID = h.CustID AND c.CategoryID = CONST_CATEGORY_ROBOT) AS IsTWRobot
		FROM Temp_RobotClassificationHistory AS h
			INNER JOIN Temp_TransLatestRobotClassificationDate AS ls ON h.TransID = ls.TransID AND h.LastModifiedDate = ls.ScannedDate
    )
    SELECT 	TransID
		,	CASE 
				WHEN IsTWRobot = 1 THEN RobotType
                ELSE CONST_ROBOTTYPE_NOTROBOT
			END AS RobotType
        ,	IsAIRobot AS IsRobot
    FROM CTE_temp;
    
 END$$

DELIMITER ;