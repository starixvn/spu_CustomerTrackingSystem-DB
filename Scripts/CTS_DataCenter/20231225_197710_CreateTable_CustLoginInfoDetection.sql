/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231225@Thomas.Nguyen
Task:	 	new table for CC 305/3005 System Detect Unauthorized Login.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231225@Thomas.Nguyen: Created [Redmine ID: #197710]
Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE CustomerLoginInfoDetection(
		CustID								INT UNSIGNED NOT NULL PRIMARY KEY
	,	CTSCustID							BIGINT UNSIGNED NOT NULL
	, 	FirstBetDate						DATETIME
	,	Bot									INT UNSIGNED
	,	InvalidBrowser						INT UNSIGNED
	,	BotTransPercentage					DECIMAL(6,2)
	,	InvalidBrowserInfoTransPercentage	DECIMAL(6,2)
	,	DetectionDate						DATETIME
	,	INDEX IX_CustomerLoginInfoDetection_CTSCustID(CTSCustID)
);
