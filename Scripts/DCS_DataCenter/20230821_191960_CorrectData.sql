/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230821@Jonathan.Doan
	Task:	 	Correct BotDetectionValue 64 for Samsung Internet, HeyTab Browser & Android webview [Redmine ID: #191960]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230821@Jonathan.Doan: Created [Redmine ID: #191960]
	Reviewer:
*/
USE DCS_DataCenter;

CREATE TABLE `Transaction07_Temp` (
  `TransID` BIGINT UNSIGNED NOT NULL,
  `UserAgentKey` VARCHAR(32) DEFAULT NULL,
  `BotDetectionValue` BIT(32) DEFAULT NULL,
  PRIMARY KEY (`TransID`),
  KEY `IX_Transaction07_Temp_UserAgentKey` (`UserAgentKey`),
  KEY `IX_Transaction07_Temp_BotDetectionValue` (`BotDetectionValue`)
) ENGINE=InnoDB;

/***** PARTITION(pw202321) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202321) AS trans
WHERE trans.CreatedDate > '2023-05-22';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202322) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202322) AS trans;

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202323) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202323) AS trans;

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202324) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202324) AS trans;

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202325) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202325) AS trans;

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202326) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202326) AS trans;

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202327) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202327) AS trans;

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 1 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-07-09'
	AND CreatedDate < '2023-07-18';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64, 264);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
    OR	(tmp.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 2 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-07-18'
	AND CreatedDate < '2023-07-25';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%');

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 3 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-07-25'
	AND CreatedDate < '2023-08-01';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%');

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 4 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-08-01'
	AND CreatedDate < '2023-08-08';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%');

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 5 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-08-08'
	AND CreatedDate < '2023-08-15';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%');

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 6 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-08-15'
	AND CreatedDate < '2023-08-22';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%');

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw999999) - PART 7 ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
WHERE CreatedDate >= '2023-08-22';

DELETE FROM Transaction07_Temp
WHERE BotDetectionValue NOT IN (64);

UPDATE DCS_DataCenter.Transaction07 AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR 	(tmp.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%');


/***** DROP TABLE TEMP ****************************************************/
DROP TABLE Transaction07_Temp;