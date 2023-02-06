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
			- 20210818@Harvey.Nguyen: 	Created [Redmine ID: #160382]
			- 20210907@Long.Luu: 		Update Robot Users rules  [Redmine ID: #161232]
			- 20220214@Long.Luu: 		Support new category for Good & Bad Robot User [Redmine ID: #167726]
			- 20220603@Long.Luu: 		Merge Robot AI & Robot TW [Redmine ID: #172561]
			- 20230119@Victoria.Le		Change to check IsRobot from CTSCustomerClassification instead of RobotDetection [Redmine ID: #181994]
            
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
	DECLARE CONST_ROBOTTYPE_BAD 			INT DEFAULT 2;
	DECLARE	CONST_ROBOTTYPE_GOOD 			INT DEFAULT 1;
	
    DECLARE	CONST_CATEGORYGROUP_BADROBOT 	INT DEFAULT 163;
    DECLARE	CONST_CATEGORYGROUP_GOODROBOT	INT DEFAULT 164;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			CustID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        ,	TransID		BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_Trans(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Result;  
	CREATE TEMPORARY TABLE Temp_Result
    (
			CustID		BIGINT UNSIGNED
        ,	TransID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        , 	RobotType	TINYINT
		,	IsRobot		TINYINT
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
				
	INSERT INTO Temp_Result(CustID, TransID, TransDate, RobotType, IsRobot)    
    SELECT	t.CustID
		,	t.TransID
        ,	t.TransDate
		,	CASE 
				WHEN cc.CategoryID = CONST_CATEGORYGROUP_BADROBOT THEN CONST_ROBOTTYPE_BAD
				WHEN cc.CategoryID = CONST_CATEGORYGROUP_GOODROBOT THEN CONST_ROBOTTYPE_GOOD
				ELSE CONST_ROBOTTYPE_NOTROBOT
			END AS RobotType
		,	CASE
				WHEN cc.CategoryID IN (CONST_CATEGORYGROUP_BADROBOT,CONST_CATEGORYGROUP_GOODROBOT) THEN 1
				ELSE 0
			END AS IsRobot
    FROM Temp_Trans AS t
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = t.CustID
		STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = clss.CategoryID;    
    
    SELECT 	r.TransID
		,	r.RobotType
		,	r.IsRobot
    FROM Temp_Result AS r
    ORDER BY r.TransID ASC;
    
 END$$
DELIMITER ;