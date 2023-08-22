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

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202321) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE trans.CreatedDate > '2023-05-22'
	AND (
			(trans.BotDetectionValue = 64
            AND ua.BrowserID = 11)
		OR	(trans.BotDetectionValue = 64
			AND ua.BrowserID = 4
			AND ua.OSID = 1
			AND ua.UserAgent like '%HeyTap%')
		OR	(trans.BotDetectionValue = 264
			AND ua.BrowserID = 1
			AND ua.OSID = 1)
    );

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202322) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202323) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202324) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202325) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202326) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw202327) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);

UPDATE DCS_DataCenter.Transaction07 PARTITION(pw999999) AS trans
	INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
SET 	trans.Flagged = 1
	,	trans.BotDetectionValue = 0
	,	trans.BotComponentID = 1
WHERE (trans.BotDetectionValue = 64
		AND ua.BrowserID = 11)
	OR	(trans.BotDetectionValue = 64
		AND ua.BrowserID = 4
		AND ua.OSID = 1
		AND ua.UserAgent like '%HeyTap%')
	OR	(trans.CreatedDate < '2023-07-18'
		AND trans.BotDetectionValue = 264
		AND ua.BrowserID = 1
		AND ua.OSID = 1);