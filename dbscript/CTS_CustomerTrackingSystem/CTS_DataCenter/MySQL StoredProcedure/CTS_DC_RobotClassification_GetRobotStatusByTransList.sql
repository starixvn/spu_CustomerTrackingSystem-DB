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
			- 20220603@Long.Luu: Merge Robot AI & Robot TW [Redmine ID: #172561]
            
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
    DECLARE CONST_ROBOTTYPE_NOTROBOT		TINYINT DEFAULT -2;
    DECLARE CONST_ROBOTTYPE_ROBOT 			TINYINT DEFAULT -1;
    DECLARE	CONST_CATEGORYGROUP_ROBOT 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYGROUP_BADROBOT 	INT DEFAULT 163;
    DECLARE	CONST_CATEGORYGROUP_GOODROBOT	INT DEFAULT 164;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			CustID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        ,	TransID		BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_Trans(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AIRobotTrans;
    CREATE TEMPORARY TABLE Temp_AIRobotTrans(
			CustID		BIGINT UNSIGNED
        ,	TransID		BIGINT UNSIGNED
        ,	TransDate	DATETIME(3)
        ,	RobotType	TINYINT
        
        ,	PRIMARY KEY PK_Temp_AIRobotTrans(CustID,TransDate,TransID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotUserTrans;
    CREATE TEMPORARY TABLE Temp_RobotUserTrans(
			CustID			BIGINT UNSIGNED
        ,	TransID			BIGINT UNSIGNED
		,	TransDate		DATETIME(3)
        
        ,	PRIMARY KEY 	PK_Temp_RobotUserTrans(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Result;  
	CREATE TEMPORARY TABLE Temp_Result
    (
			CustID		BIGINT UNSIGNED
        ,	TransID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        , 	RobotType	TINYINT
        
        ,	PRIMARY KEY 	PK_Temp_Result(CustID,TransDate,TransID)
    );
    
    #=========================================================================
    INSERT INTO Temp_Trans(CustID,TransDate,TransID)
	SELECT  js.CustID
		,	js.TransDate
		,	js.TransID
	FROM JSON_TABLE(ip_TransList,
					 "$[*]" COLUMNS(
								CustID			BIGINT UNSIGNED 	PATH "$.CustID" 
							,	TransDate		DATETIME(3) 		PATH "$.TransDate"                               
							,	TransID			BIGINT UNSIGNED 	PATH "$.TransID"
						)
				) AS js;    

    /*AI Robot*/
	INSERT INTO Temp_AIRobotTrans(CustID, TransID, TransDate, RobotType)
    SELECT	t.CustID
		,	t.TransID
        ,	t.TransDate
		,	w.RobotType
    FROM Temp_Trans AS t,
        LATERAL(
			SELECT ai.RobotType
			FROM CTS_DataCenter.RobotClassification AS ai
			WHERE ai.CustID = t.CustID
				AND ai.FromDate <= t.TransDate
			ORDER BY ai.FromDate DESC
			LIMIT 1
		) AS w;
   
    /*Robot User*/
	INSERT INTO Temp_RobotUserTrans(CustID, TransID, TransDate)    
    SELECT	t.CustID
		,	t.TransID
        ,	t.TransDate
    FROM Temp_Trans AS t,
        LATERAL(
			SELECT h.CategoryID
			FROM CTS_DataCenter.CTSCustomerClassification_History AS h
				INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = h.CategoryID
			WHERE h.CustID = t.CustID
				AND cc.CategoryGroup IN (CONST_CATEGORYGROUP_ROBOT, CONST_CATEGORYGROUP_BADROBOT, CONST_CATEGORYGROUP_GOODROBOT)
				AND h.LastModifiedDate <= t.TransDate
			ORDER BY h.LastModifiedDate DESC
			LIMIT 1
		) AS tmp;    
    
    DELETE r
    FROM Temp_RobotUserTrans AS r
		INNER JOIN Temp_AIRobotTrans AS ai ON ai.CustID = r.CustID AND ai.TransID = r.TransID;
    
    /*Get Result*/
    INSERT INTO Temp_Result (CustID, TransID, TransDate, RobotType)
    SELECT CustID, TransID, TransDate, RobotType FROM Temp_AIRobotTrans;
    
    INSERT INTO Temp_Result (CustID, TransID, TransDate, RobotType)
    SELECT CustID, TransID, TransDate, CONST_ROBOTTYPE_ROBOT FROM Temp_RobotUserTrans;
    
    INSERT INTO Temp_Result (CustID, TransID, TransDate, RobotType)
    SELECT t.CustID, t.TransID, t.TransDate, CONST_ROBOTTYPE_NOTROBOT
    FROM Temp_Trans AS t
	WHERE NOT EXISTS (SELECT 1 FROM Temp_AIRobotTrans AS ai WHERE ai.CustID = t.CustID AND ai.TransID = t.TransID)
		AND NOT EXISTS (SELECT 1 FROM Temp_RobotUserTrans AS r WHERE r.CustID = t.CustID AND r.TransID = t.TransID);
    
    SELECT 	r.TransID
		,	r.RobotType
		,	EXISTS (SELECT 1 FROM CTS_DataCenter.RobotDetection AS rd WHERE rd.CustID = r.CustID AND rd.CreatedDate <= r.TransDate) AS IsRobot
    FROM Temp_Result AS r
    ORDER BY r.TransID ASC;
 END$$
DELIMITER ;