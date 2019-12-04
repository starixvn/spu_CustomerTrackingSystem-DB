/*
Creator: 20190521@John
Task:	 FPS Reform [Redmine ID: 105252]
Server:  
DBName:	CTS_Admin

Revisions: 
Reviewer:
*/

CREATE DATABASE IF NOT EXISTS CTS_Admin;

CREATE TABLE CTS_Admin.Subscriber (
	SubscriberID		INT			NOT NULL	AUTO_INCREMENT
,	SubscriberName		VARCHAR(50) NOT NULL
,	SubscriberPrefix	VARCHAR(30) NULL
,	CreatedDate			DATETIME	 	NULL
,	CreatedBy			INT NULL
,	SubscriberType		TINYINT	UNSIGNED	NULL	# 0: Credit, 1: Deposit 			
,	SubscriberStatus		TINYINT	NOT NULL	COMMENT '0: Inactive; 1: Active; -1: Unhandle (sub that not integrate, is insert new from transaction)'
,	IsTest				TINYINT	NULL
,	PRIMARY KEY	PK_Subscriber_SubscriberID (SubscriberID)
,	UNIQUE KEY IX_Subscriber_SubscriberName_SubScriberPrefix (SubscriberName,SubScriberPrefix)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

CREATE TABLE CTS_Admin.UserSubscriber (
	UserID				INT 		NOT NULL
,	SubscriberID		INT			NOT NULL
,	CreatedDate			DATETIME	NULL
,	CreatedBy			INT			NULL
,	PRIMARY KEY	CIX_UserSubscriber_UserID_SubscriberID (UserID,SubscriberID)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE CTS_Admin.LogType (
	LogTypeID			SMALLINT 						NOT NULL	AUTO_INCREMENT
,	LogTypeName			VARCHAR(50) 					NOT NULL
,	LogTypeDescription	VARCHAR(200) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci' NULL 						COMMENT 'NVARCHAR'
,	PRIMARY KEY	PK_LogType_LogTypeID (LogTypeID)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

CREATE TABLE CTS_Admin.UserLog (
	LogTypeID			SMALLINT 						NOT NULL
,	SPName				VARCHAR(100)					NULL
,	LogInfo				VARCHAR(500) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci' NULL COMMENT 'NVARCHAR'
,	CreatedDate			DATETIME	 NULL
,	CreatedBy			INT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;