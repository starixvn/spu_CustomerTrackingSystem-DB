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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(
			CustID		BIGINT UNSIGNED
		,	TransDate	DATETIME(3)
        ,	TransID		BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_Trans(CustID,TransDate,TransID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistsRobotUserHistory;
    CREATE TEMPORARY TABLE Temp_ExistsRobotUserHistory(
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransRobotType;  
	CREATE TEMPORARY TABLE Temp_TransRobotType
    (
			TransID		BIGINT UNSIGNED
        , 	RobotType	TINYINT
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotTypePriority;
    CREATE TEMPORARY TABLE Temp_RobotTypePriority(
			RobotType 	TINYINT UNSIGNED
        ,	Priority	TINYINT UNSIGNED	
    );
    
    INSERT INTO Temp_RobotTypePriority(RobotType, Priority)
    VALUES	(2,2)
		,	(0,1)
        ,	(1,0);
    
    #=========================================================================
    INSERT INTO Temp_Trans(CustID,TransDate,TransID)
	SELECT  js.CustID
		,	js.TransDate
		,	js.TransID
	FROM JSON_TABLE(ip_TransList,
					 "$[*]" COLUMNS(
								CustID			BIGINT UNSIGNED PATH "$.CustID" 
							,	TransDate		DATETIME(3) PATH "$.TransDate"                               
							,	TransID			BIGINT UNSIGNED PATH "$.TransID"
						)
				) AS js;    
            
    #======GET Existing Robot Type ================================================================    
	INSERT INTO Temp_ExistsRobotUserHistory(CustID, TransDate, TransID, CategoryID, LastModifiedDate)    
    SELECT	tmpTs.CustID
		,	tmpTs.TransDate
		,	tmpTs.TransID
		,	tmpRc.CategoryID
        ,	tmpRc.LastModifiedDate
    FROM Temp_Trans AS tmpTs,
        LATERAL(
			SELECT clh.CategoryID, clh.LastModifiedDate
			FROM CTS_DataCenter.CTSCustomerClassification_History AS clh
			WHERE clh.CustID = tmpTs.CustID
				AND clh.CategoryID IN (61, 81, 161, 210) 
				AND clh.LastModifiedDate <= tmpTs.TransDate
			ORDER BY clh.LastModifiedDate DESC
			LIMIT 1
		) AS tmpRc
	WHERE tmpRc.CategoryID <> 210;    
    
	INSERT INTO Temp_ExistsRobotClassification(CustID, TransDate, TransID, Priority)
	WITH CTE_TransRobot AS(
		SELECT	tmpTr.CustID
			,	tmpTr.TransDate
			,	tmpTr.TransID
			, 	rcl.SportTypeID
			, 	rcl.LiveIndicator        
			,	rcl.BetTypeID
			,	MAX(FromDate) AS FromDate
		FROM Temp_Trans AS tmpTr
			INNER JOIN CTS_DataCenter.RobotClassification AS rcl ON tmpTr.CustID = rcl.CustID
				  AND (tmpTr.TransDate > rcl.FromDate OR tmpTr.TransDate BETWEEN rcl.FromDate AND rcl.ToDate)
		GROUP BY tmpTr.CustID,	tmpTr.TransDate, tmpTr.TransID, rcl.SportTypeID, rcl.LiveIndicator, rcl.BetTypeID
	)
    SELECT	cte.CustID
		,	cte.TransDate
		,	cte.TransID
        ,	MAX(tmpPr.Priority) 
	FROM 	CTE_TransRobot AS cte
		INNER JOIN CTS_DataCenter.RobotClassification AS rcl1 ON cte.CustID = rcl1.CustID AND cte.FromDate = rcl1.FromDate
					AND cte.SportTypeID = rcl1.SportTypeID AND cte.LiveIndicator = rcl1.LiveIndicator AND cte.BetTypeID = rcl1.BetTypeID
		INNER JOIN Temp_RobotTypePriority AS tmpPr ON tmpPr.RobotType = rcl1.RobotType
	GROUP BY cte.CustID
		,	cte.TransDate
		,	cte.TransID;
  
	INSERT INTO  Temp_TransRobotType(TransID,RobotType)
    SELECT 	tmpTr.TransID
		,	(CASE WHEN tmpRh.CategoryID IN (61, 81, 161) THEN tmpPr.RobotType ELSE -1 END) AS RobotType
    FROM Temp_ExistsRobotClassification AS tmpTr
		LEFT JOIN Temp_ExistsRobotUserHistory AS tmpRh ON tmpTr.TransID = tmpRh.TransID
		LEFT JOIN Temp_RobotTypePriority AS tmpPr ON tmpPr.Priority = tmpTr.Priority;     
        
    SELECT 	tmpTs.TransID
		,	(	CASE	WHEN tmpRh.TransID IS NULL THEN -4
						WHEN tmpRt.TransID IS NOT NULL THEN tmpRt.RobotType
						ELSE -1
                END) AS RobotType
		,	EXISTS (SELECT 1 FROM CTS_DataCenter.RobotDetection AS rd WHERE rd.CustID = tmpTs.CustID AND rd.CreatedDate < tmpTs.TransDate) AS IsRobot
    FROM Temp_Trans AS tmpTs
		LEFT JOIN Temp_TransRobotType AS tmpRt ON tmpTs.TransID = tmpRt.TransID
		LEFT JOIN Temp_ExistsRobotUserHistory AS tmpRh ON tmpTs.TransID = tmpRh.TransID;
 END$$

DELIMITER ;