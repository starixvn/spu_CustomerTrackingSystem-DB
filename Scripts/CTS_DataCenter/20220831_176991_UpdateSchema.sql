/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220905@Aries.Nguyen
Task:	 	CTS - Robot Classification - Wrong mapping to push CC and ABI Danger [Redmine ID: 172497] 	
DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;
DROP TABLE AssociatedGroupAccount; 
CREATE TABLE AssociatedGroupAccount (
    GroupID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    CTSCustID BIGINT UNSIGNED NOT NULL,
    IsAuto BIT(1) DEFAULT 0,
    Remark VARCHAR(200) DEFAULT NULL,
    Created DATETIME DEFAULT CURRENT_TIMESTAMP,
    CreatedBy INT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (GroupID , CTSCustID),
    KEY IX_AssociatedGroupAccount_CTSCustID (CTSCustID)
)  ENGINE=INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE AssociatedGroup;
CREATE TABLE AssociatedGroup (
    GroupID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    GroupName VARCHAR(100) DEFAULT NULL,
    ABI INT DEFAULT NULL, 
    AllCredit SMALLINT DEFAULT 0,
    AllLicensee SMALLINT DEFAULT 0,
    Sites LONGTEXT DEFAULT NULL,
    HasDevice BIT(1) DEFAULT 0,
    HasManual BIT(1) DEFAULT 0,
    HasIP BIT(1) DEFAULT 0,
	HasAI BIT(1) DEFAULT 0,
    Remark VARCHAR(200) DEFAULT NULL,
    IsDisable BIT(1) DEFAULT 0,
    Created DATETIME DEFAULT CURRENT_TIMESTAMP,
    CreatedBy INT UNSIGNED DEFAULT NULL,
    Modified DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ModifiedBy INT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (GroupID)
)  ENGINE=INNODB;


USE CTS_DataCenter;
CREATE TABLE CTSAuditLog (
   ID bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
   EventName varchar(100) DEFAULT NULL,
   Info json DEFAULT NULL,
   CreatedBy bigint unsigned,
   CreatedDate datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;