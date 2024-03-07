/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240306@Thomas.Nguyen
Task:	 	new log table for tracking TVS void request.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240306@Thomas.Nguyen: Created [Redmine ID: #201993]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE TVSVoidRequest_History
	ADD InsertedTime DATETIME(3);

CREATE TABLE TVSVoidRequest_Log(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
	CustIDs LONGTEXT COLLATE utf8_unicode_ci DEFAULT NULL,
	ReasonID INT DEFAULT NULL,
	CreatedBy INT DEFAULT NULL,
	CreatedDate DATETIME(3) DEFAULT NULL,
	IsParlay BIT DEFAULT NULL,
	SportType SMALLINT DEFAULT NULL,
	IssueTypeID TINYINT DEFAULT NULL,
	INDEX IX_TVSVoidRequest_Log_CreatedDate (CreatedDate),
	INDEX IX_TVSVoidRequest_Log_ReasonID (ReasonID)
);
