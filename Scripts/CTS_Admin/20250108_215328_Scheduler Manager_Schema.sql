/*<info serverAlias="CTSMain-CTS_Admin" databaseType="2"></info>*/
/*
		Created:	20250102@Adam.Tran
		Task:		CTS - Main Service - Extend Functions Scheduler manager [Redmine ID: 215328]
		DB:			CTS_Admin
		Original:

		Revisions: 
			- 20250102@Adam.Tran:   Created
			
		Param's Explanation (filtered by):
*/

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
	JobType VARCHAR(300) NOT NULL,
	APIUrl VARCHAR(500) NOT NULL,
	MethodName VARCHAR(300) NOT NULL,
    Controller VARCHAR(300) NOT NULL,
	IsActive TINYINT DEFAULT 0,
	IsDisable TINYINT DEFAULT 0,
	IsNew TINYINT DEFAULT 0,
	PRIMARY KEY(JobName, GroupName)
)ENGINE=InnoDB;

DROP TABLE IF EXISTS CTSTrigger;

CREATE TABLE CTSTrigger (
	TriggerID INT AUTO_INCREMENT UNIQUE,
    TriggerName VARCHAR(300) NOT NULL,	
	JobName VARCHAR(300) NOT NULL,
	TriggerType VARCHAR(300) NOT NULL,
	IntervalInSecond INT UNSIGNED DEFAULT NULL,
	CronExpression VARCHAR(300) DEFAULT NULL,
	PRIMARY KEY(TriggerName, JobName)
)ENGINE=InnoDB;








