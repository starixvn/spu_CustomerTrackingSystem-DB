/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20221107@Casey.Huynh
	Task: Log DCSAccount Transform to CTS
	DB: CTS_DataCenter
  
	Revisions:
		- 20221107@Casey.Huynh: created  [Redmine ID: #180182]

	Param's Explanation:
*/


USE CTS_Log; 

CREATE TABLE AccountTransformStatus_Log (
  ID bigint unsigned NOT NULL AUTO_INCREMENT,
  AccountID bigint unsigned DEFAULT NULL,
  IsCTSTransformed tinyint DEFAULT NULL,
  UpdateIsCTSTransformed tinyint DEFAULT NULL,
  InsertTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (ID),
  INDEX IX_AccountTransformStatus_Log(AccountID)
) ENGINE=InnoDB;

CREATE TABLE CTSCustomer_Log (
  ID bigint unsigned NOT NULL AUTO_INCREMENT,
  CTSCustID bigint unsigned DEFAULT NULL,
  SubscriberID INT DEFAULT NULL,
  CustID bigint unsigned DEFAULT NULL,
  UserName VARCHAR(50),
  RegisterName VARCHAR(50),
  RoleID tinyint,
  CustSubID bigint unsigned DEFAULT NULL,
  InsertTimeCTSDebugLog DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	PRIMARY KEY (ID)
  ,	INDEX IX_CTSCustomer_Log_CustID(CustID)
) ENGINE=InnoDB;

