/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220707@Aries.Nguyen
    Task:	 	[CTS] Fraud Group Management [Redmine ID: 167748] 	
    DBName:		CTS_DataCenter
*/
USE CTS_Admin;
INSERT INTO CTS_Admin.LogType (LogTypeID, LogTypeName) VALUES (34, 'AssociatedGroupMonitor');

USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (97, 'AssociatedGroup_BatchSize', 'AssociatedGroup_BatchSize', 'BIGINT', 500),
	   (98, 'AssociatedGroup_LastGroupID', 'AssociatedGroup_LastGroupID', 'BIGINT', 0),
	   (99, 'AssociatedGroup_LastCTSCustID', 'AssociatedGroup_LastCTSCustID', 'BIGINT', 0);

DROP TABLE IF EXISTS AssociatedGroup;
CREATE TABLE AssociatedGroup (
    GroupID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    GroupName VARCHAR(100),
    ABI INT,
    Remark VARCHAR(200),
    IsDisable BIT DEFAULT 0,
    Created DATETIME DEFAULT CURRENT_TIMESTAMP,
    CreatedBy INT UNSIGNED,
    Modified DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ModifiedBy INT UNSIGNED
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4 COLLATE = UTF8MB4_0900_AI_CI;

DROP TABLE IF EXISTS AssociatedGroupAccount;
CREATE TABLE AssociatedGroupAccount (
    GroupID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    CTSCustID BIGINT UNSIGNED,
    IsAuto BIT DEFAULT 0,
    Remark VARCHAR(200),
    Created DATETIME DEFAULT CURRENT_TIMESTAMP,
    CreatedBy INT UNSIGNED,
    PRIMARY KEY (GroupID , CTSCustID),
    INDEX IX_AssociatedGroupAccount_CTSCustID(CTSCustID)
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4 COLLATE = UTF8MB4_0900_AI_CI;
