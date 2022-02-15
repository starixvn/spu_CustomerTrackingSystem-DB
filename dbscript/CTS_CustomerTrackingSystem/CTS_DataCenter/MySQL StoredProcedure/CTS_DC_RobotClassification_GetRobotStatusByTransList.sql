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
    DECLARE	CONST_CATEGORYID_ROBOTUSERS 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYID_BADROBOTUSERS 		INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_GOODROBOTUSERS 	INT DEFAULT 164;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
    
    DECLARE CONST_ROBOTTYPE_NOTROBOT 	TINYINT DEFAULT -2;
    DECLARE CONST_ROBOTTYPE_ROBOT 		TINYINT DEFAULT -1;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT DEFAULT 2;
    
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
        ,	CategoryID			SMALLINT
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
            
    INSERT INTO Temp_RobotClassificationHistory(CustID, TransDate, TransID, CategoryID, LastModifiedDate)    
    SELECT	t.CustID
		,	t.TransDate
		,	t.TransID
		,	w.CategoryID
        ,	w.LastModifiedDate
    FROM Temp_Trans AS t,
        LATERAL(
			SELECT CategoryID, LastModifiedDate
			FROM CTS_DataCenter.CTSCustomerClassification_History
			WHERE CustID = CustID
				AND SportGroupID = CONST_GROUP_PA
				AND CategoryID IN (CONST_CATEGORYID_ROBOTUSERS, 81, 161, CONST_CATEGORYID_BADROBOTUSERS, CONST_CATEGORYID_GOODROBOTUSERS) 
				AND LastModifiedDate <= t.TransDate
			ORDER BY LastModifiedDate DESC
			LIMIT 1
		) AS w;
    
    INSERT INTO Temp_TransLatestRobotClassificationDate(TransID, ScannedDate)
    SELECT	TransID
		,	MAX(LastModifiedDate)
	FROM Temp_RobotClassificationHistory
	GROUP BY TransID;
    
	SELECT 	h.TransID
		,	(	CASE	
					WHEN h.CategoryID = CONST_CATEGORYID_GOODROBOTUSERS THEN CONST_ROBOTTYPE_GOOD
					WHEN h.CategoryID = CONST_CATEGORYID_BADROBOTUSERS THEN CONST_ROBOTTYPE_BAD
                    WHEN h.CategoryID = CONST_CATEGORYID_ROBOTUSERS THEN CONST_ROBOTTYPE_ROBOT
					ELSE CONST_ROBOTTYPE_NOTROBOT
                END
			) AS RobotType
		,	EXISTS (SELECT 1 FROM CTS_DataCenter.RobotDetection AS r WHERE r.CustID = h.CustID AND r.CreatedDate < h.TransDate) AS IsRobot
    FROM Temp_RobotClassificationHistory AS h
		INNER JOIN Temp_TransLatestRobotClassificationDate AS ls ON h.TransID = ls.TransID AND h.LastModifiedDate = ls.ScannedDate;
 END$$

DELIMITER ;