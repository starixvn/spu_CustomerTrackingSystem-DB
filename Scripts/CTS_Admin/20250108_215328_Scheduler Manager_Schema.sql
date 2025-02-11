/*<info serverAlias="CTSMain-CTS_Admin" databaseType="2"></info>*/
/*
Creator:	20250102@Adam.Tran
Task:	 	CTS - Main Service - Extend Functions Scheduler manager [Redmine ID: 215328]
Server:  	Master
DBName:		CTS_Admin

Revisions: 
		- 20250102@Adam.Tran:   Created

*/

USE CTS_Admin;

DROP TABLE IF EXISTS CTSGroupJob;

CREATE TABLE CTSGroupJob (
    GroupID 	INT AUTO_INCREMENT UNIQUE,
    GroupName 	VARCHAR(300) NOT NULL,	
	PRIMARY KEY(GroupName)
)ENGINE=InnoDB;


DROP TABLE IF EXISTS CTSJob;

CREATE TABLE CTSJob (
	JobID INT AUTO_INCREMENT UNIQUE,
    JobName VARCHAR(300) NOT NULL,
	GroupName VARCHAR(300) NOT NULL,
	EnvironmentID	INT DEFAULT 1, 
	JobType VARCHAR(300) NOT NULL,
	APIUrl VARCHAR(500) NOT NULL,
	MethodName VARCHAR(300) NOT NULL,
    Controller VARCHAR(300) NOT NULL,
	IsStartByDefault TINYINT DEFAULT 0,
	IsDisable TINYINT DEFAULT 0,
	IsAdjust TINYINT DEFAULT 0,
	PRIMARY KEY(JobID)
)ENGINE=InnoDB;

DROP TABLE IF EXISTS CTSTrigger;

CREATE TABLE CTSTrigger (
	TriggerID INT AUTO_INCREMENT UNIQUE,
    TriggerName VARCHAR(300) NOT NULL,	
	JobName VARCHAR(300) NOT NULL,
	EnvironmentID	INT DEFAULT 1, 
	TriggerType VARCHAR(300) NOT NULL,
	IntervalInSecond INT UNSIGNED DEFAULT NULL,
	CronExpression VARCHAR(300) DEFAULT NULL,
	IsDisable TINYINT DEFAULT 0,
	PRIMARY KEY(TriggerID)
)ENGINE=InnoDB;








