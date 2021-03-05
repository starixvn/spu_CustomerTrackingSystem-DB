/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DBA_Monitor_SPMetric_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_SPMetric_Insert`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210127@Aries.Nguyen
		Task:		Grafana Monitor SP Metric 
		DB:			MonDB
		Original:

		Revisions:
			- 20210127@Aries.Nguyen: Created [Redmine ID: #149662]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Monitor_SPMetric_Insert();
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_SummaryProgram;
	CREATE TEMPORARY TABLE Temp_SummaryProgram (
			`Type` 						VARCHAR(20)
		,	`Database` 					VARCHAR(64)
		,	`Name` 						VARCHAR(64)
        ,	`GroupID`					INT
		,	`Count_Star` 				BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Errors` 				BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Warnings` 				BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Rows_Affected` 		BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Rows_Sent` 			BIGINT UNSIGNED DEFAULT 0
		,	PRIMARY KEY (`Database`,`Name`)
	);
 
	DROP TEMPORARY TABLE IF EXISTS Temp_SPStar;
	CREATE TEMPORARY TABLE Temp_SPStar (
			`Type` 						VARCHAR(20)
		,	`Database` 					VARCHAR(64)
		,	`Name` 						VARCHAR(64)
		,	`Count_Star` 				BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Errors` 				BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Warnings` 				BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Rows_Affected` 		BIGINT UNSIGNED DEFAULT 0
		,	`Sum_Rows_Sent` 			BIGINT UNSIGNED DEFAULT 0
		,	PRIMARY KEY (`Database`,`Name`)
	);
 
 
	INSERT IGNORE INTO Temp_SummaryProgram(`Type`, `Database`, `Name`, `Count_Star`, `Sum_Errors`, `Sum_Warnings`, `Sum_Rows_Affected`, `Sum_Rows_Sent` )
	SELECT 
			OBJECT_TYPE
		, 	OBJECT_SCHEMA
		, 	OBJECT_NAME
		, 	COUNT_STAR
		,	SUM_ERRORS
		,	SUM_WARNINGS
		,	SUM_ROWS_AFFECTED
		,	SUM_ROWS_SENT
	FROM  	performance_schema.events_statements_summary_by_program AS suPro;
	
    UPDATE Temp_SummaryProgram AS suPr
		LEFT JOIN  MonDB.DBA_CTS_DataFlow_Monitor AS flow ON suPr.`Name` = flow.SPName
	SET suPr.GroupID = IFNULL(flow.GroupID,0);
    
	INSERT IGNORE INTO Temp_SPStar( `Database`, `Name`, `Count_Star`, `Sum_Errors`, `Sum_Warnings`, `Sum_Rows_Affected`, `Sum_Rows_Sent`)
	SELECT
			suPr.`Database`
		,	suPr.`Name`
		,	tbl.`Count_Star_Flag`
		,	tbl.`Sum_Errors_Flag`
		,	tbl.`Sum_Warnings_Flag`
		,	tbl.`Sum_Rows_Affected_Flag`
		,	tbl.`Sum_Rows_Sent_Flag`
	FROM Temp_SummaryProgram AS suPr,
	LATERAL(
			SELECT 
					mo.`Count_Star_Flag`
				,	mo.`Sum_Errors_Flag`
				,	mo.`Sum_Warnings_Flag`
				,	mo.`Sum_Rows_Affected_Flag`
				,	mo.`Sum_Rows_Sent_Flag`
			FROM MonDB.DBA_SPMonitor as mo
			WHERE suPr.`Database` = mo.`Database` 
				AND suPr.`Name` = mo.`Name`
			ORDER BY mo.RowID DESC
			LIMIT 1 
	) AS tbl;

	INSERT INTO DBA_SPMonitor(
			`Database`
		, 	`GroupID`
		, 	`Name`
		, 	`Type`
		, 	`Count_Star`
		, 	`Count_Star_Flag`
		,	`Sum_Errors`
		, 	`Sum_Errors_Flag`
		, 	`Sum_Warnings`
		, 	`Sum_Warnings_Flag`
		, 	`Sum_Rows_Affected`
		,	`Sum_Rows_Affected_Flag` 
		,	`Sum_Rows_Sent`
		,	`Sum_Rows_Sent_Flag`
        , 	`Created`
	)
	SELECT 
			suPr.`Database`
		,	suPr.`GroupID`
		,	suPr.`Name`
		,	suPr.`Type`
	
		,	CASE	WHEN suPr.Count_Star >=  IFNULL(spSt.Count_Star,0) THEN suPr.Count_Star - IFNULL(spSt.Count_Star,0) 
					ELSE suPr.Count_Star 
			END AS Count_Star
		,	suPr.`Count_Star` AS `Count_Star_Flag`
    
		,	CASE	WHEN suPr.Sum_Errors >=  IFNULL(spSt.Sum_Errors,0) THEN suPr.Sum_Errors - IFNULL(spSt.Sum_Errors,0) 
					ELSE suPr.Sum_Errors 
			END AS Sum_Errors
		,	suPr.`Sum_Errors` AS `Sum_Errors_Flag`
    
		,	CASE	WHEN suPr.Sum_Warnings >=  IFNULL(spSt.Sum_Warnings,0) THEN suPr.Sum_Warnings - IFNULL(spSt.Sum_Warnings,0) 
					ELSE suPr.Sum_Warnings 
			END AS Sum_Warnings
		,	suPr.`Sum_Warnings` AS `Sum_Warnings_Flag`
    
		,	CASE 	WHEN suPr.Sum_Rows_Affected >=  IFNULL(spSt.Sum_Rows_Affected,0) THEN suPr.Sum_Rows_Affected - IFNULL(spSt.Sum_Rows_Affected,0) 
					ELSE suPr.Sum_Rows_Affected 
			END AS Sum_Rows_Affected
		,	suPr.`Sum_Rows_Affected` AS `Sum_Rows_Affected_Flag`
    
		,	CASE 	WHEN suPr.Sum_Rows_Sent >=  IFNULL(spSt.Sum_Rows_Sent,0) THEN suPr.Sum_Rows_Sent - IFNULL(spSt.Sum_Rows_Sent,0) 
					ELSE suPr.Sum_Rows_Sent 
			END AS Sum_Rows_Sent
		,	suPr.`Sum_Rows_Sent` AS `Sum_Rows_Sent_Flag`
        
        , 	UTC_TIMESTAMP()
	FROM Temp_SummaryProgram AS suPr
	LEFT JOIN Temp_SPStar AS spSt ON 	suPr.`Database` = spSt.`Database` 
								AND suPr.`Name` = spSt.`Name`;
END$$

DELIMITER ;