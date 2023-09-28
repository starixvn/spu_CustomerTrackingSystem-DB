/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230927@Jonathan.Doan
	Task:	 	Correct BotD for TV&Console, NotificationPermissions Rule, IOS ver 10/11/12 [Redmine ID: #194559]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230927@Jonathan.Doan: Created [Redmine ID: #194559]
	Reviewer:
*/
USE DCS_DataCenter;

CREATE TABLE `Transaction07_Temp` (
  `TransID` BIGINT UNSIGNED NOT NULL,
  `UserAgentKey` VARCHAR(32) DEFAULT NULL,
  `BotDetectionValue` BIT(32) DEFAULT NULL,
  PRIMARY KEY (`TransID`),
  KEY `IX_Transaction07_Temp_UserAgentKey` (`UserAgentKey`)
) ENGINE=InnoDB;

/***** PARTITION(pw202324) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202324) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202324) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202325) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202325) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202325) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202326) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202326) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202326) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202327) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202327) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202327) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202328) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202328) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202328) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202329) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202329) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202329) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202330) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202330) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202330) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202331) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202331) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202331) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202332) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202332) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202332) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202333) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202333) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202333) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202334) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202334) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202334) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202335) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202335) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202335) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202336) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202336) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202336) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202337) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202337) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202337) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202338) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202338) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202338) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

DELETE FROM Transaction07_Temp;

/***** PARTITION(pw202339) ****************************************************/
INSERT INTO Transaction07_Temp(TransID, UserAgentKey, BotDetectionValue)
SELECT 	trans.TransID
	,	trans.UserAgentKey
	,	trans.BotDetectionValue
FROM DCS_DataCenter.Transaction07 PARTITION(pw202339) AS trans
WHERE trans.BotDetectionValue IN (64, 16384, 524288);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202339) AS trans
	INNER JOIN DCS_DataCenter.Transaction07_Temp AS tmp ON tmp.TransID = trans.TransID
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = tmp.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE 	tmp.BotDetectionValue = 64
	OR 	(tmp.BotDetectionValue = 524288 AND ua.DeviceTypeID = 6)
    OR	(tmp.BotDetectionValue = 16384 AND ua.OSID = 3);

-- DELETE FROM Transaction07_Temp;

/***** DROP TABLE TEMP ****************************************************/
DROP TABLE Transaction07_Temp;