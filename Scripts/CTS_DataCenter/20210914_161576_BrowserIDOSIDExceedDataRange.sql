/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20210914@Casey.Huynh
Task:	 	BrowserID and OSID Exceed DataRange
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20210914@Casey.Huynh: Created [#161576]
Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE Browser
	MODIFY BrowserID INT UNSIGNED AUTO_INCREMENT;

ALTER TABLE OS
	MODIFY OSID INT UNSIGNED AUTO_INCREMENT;

ALTER TABLE UserAgent
		MODIFY BrowserID INT UNSIGNED
	,	MODIFY OSID INT UNSIGNED;