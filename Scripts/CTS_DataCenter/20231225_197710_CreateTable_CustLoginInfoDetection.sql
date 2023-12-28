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

DROP TABLE IF EXISTS CTS_DataCenter.CustomerLoginInfoDetection;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustomerLoginInfoDetection(
		CTSCustID			BIGINT UNSIGNED NOT NULL
	,	CustID				INT UNSIGNED NOT NULL
	, 	FirstBetDate		DATETIME
	,	Bot					INT UNSIGNED
	,	InvalidBrowser		INT UNSIGNED
	,	BotTransPercentage	DECIMAL(6,2)
	,	InvalidBrowserInfoTransPercentage	DECIMAL(6,2)
    ,	PRIMARY KEY			PK_CustomerLoginInfoDetection_CTSCustID(CTSCustID)
	,	INDEX 		 		IX_CustomerLoginInfoDetection_CustID(CustID)
	,	INDEX 		 		IX_CustomerLoginInfoDetection_FirstBetDate(FirstBetDate)
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;