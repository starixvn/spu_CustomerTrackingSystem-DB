/* LOG THE VOID REQUEST FOR FURTHER TRACKING */
	INSERT INTO CTS_DataCenter.TVSVoidRequest_History (TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate,IsParlay,SportType,IssueTypeID)
	SELECT TVSRequestID, GROUP_CONCAT(DISTINCT CustID), ReasonID, CreatedBy, NOW(),IsParlay,SportType,IssueTypeID
	FROM Temp_PA
	WHERE IsFromTVS = 1
	GROUP BY TVSRequestID, ReasonID, CreatedBy, IsParlay, SportType, IssueTypeID;




/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240306@Thomas.Nguyen
Task:	 	new log table for tracking TVS void request.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240306@Thomas.Nguyen: Created [Redmine ID: #xxxxx]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE TVSVoidRequest_History
	ADD InsertedTime DATETIME(3) AFTER CreatedDate;

CREATE TABLE TVSVoidRequest_Log(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
	CustIDs VARCHAR(2000) COLLATE utf8_unicode_ci DEFAULT NULL,
	ReasonID INT DEFAULT NULL,
	CreatedBy INT DEFAULT NULL,
	CreatedDate DATETIME(3) DEFAULT NULL,
	IsParlay BIT(1) DEFAULT NULL,
	SportType SMALLINT DEFAULT NULL,
	IssueTypeID TINYINT DEFAULT NULL,
	INDEX IX_TVSVoidRequest_Log_CreatedDate (CreatedDate),
	INDEX IX_TVSVoidRequest_Log_ReasonID (ReasonID)
);
