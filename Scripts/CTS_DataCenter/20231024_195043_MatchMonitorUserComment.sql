/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231023@Casey.Huynh
Task:	 	Match Monitor user comment Schema
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231023@Casey.Huynh: Created [Redmine ID: #195043]
Reviewer:
*/
USE CTS_DataCenter;

CREATE TABLE MatchMonitorUserComment(
	MMUserCommentID		BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	MatchID				INT NOT NULL,
	SportType			TINYINT(1) NOT NULL,
	LiveIndicator		TINYINT(1) NOT NULL,    
	BettypeID			INT NOT NULL,
    BetID				BIGINT,
    UserComment			VARCHAR(1000),
    CreatedDate			DATETIME(3),
	CreatedBy			INT,
	ModifiedDate		DATETIME(3),
    ModifiedBy			INT,

    INDEX IX_MatchMonitorUserComment_MatchID(MatchID,SportType,LiveIndicator,BettypeID,CreatedBy),
    INDEX IX_MatchMonitorUserComment_SportType(SportType)
);

CREATE TABLE MatchMonitorUserCommentDetails(
	MMUserCommentID	BIGINT UNSIGNED NOT NULL,
    CommentType		TINYINT COMMENT '0: Incorrect, 1 Correct',
	Reason			SMALLINT COMMENT '-1: Others, Else MM Reason',
	FromTransInfo	VARCHAR(30),
    ToTransInfo		VARCHAR(30),
	
    PRIMARY KEY (MMUserCommentID, CommentType, Reason),
    INDEX  IX_MatchMonitorUserCommentDetails_CommentType(CommentType),
    INDEX  IX_MatchMonitorUserCommentDetails_Reason(Reason)
);

USE CTS_Admin;
INSERT INTO CTS_Admin.LogType(LogTypeID, LogTypeName, LogTypeDescription)
VALUES(35,'Insert Match Monitor User Comment','Insert Match Monitor User Comment')
	,(36,'Update Match Monitor User Comment','Update Match Monitor User Comment')
    ,(37,'Delete Match Monitor User Comment','Update Match Monitor User Comment');
    
