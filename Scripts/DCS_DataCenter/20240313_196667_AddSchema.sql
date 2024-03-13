/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240313@Teddy.le [Redmine ID: #196667]
	Task: Init Schema
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

CREATE TABLE DCS_DataCenter.JSChallengeInfo (
  ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  CreatedTime TIMESTAMP(4) NOT NULL,
  ChallengeCode VARCHAR(50), 
  ChallengeIds VARCHAR(50) NULL DEFAULT '',
  Expect VARCHAR(100) NULL DEFAULT '',
  Actual VARCHAR(100) NULL DEFAULT '',
  Parameters VARCHAR(300) NULL DEFAULT '',
  ExeServerTimeInSecond INT UNSIGNED NOT NULL DEFAULT 0,
  ExeClientTimeInSecond INT UNSIGNED NOT NULL DEFAULT 0,
  Result TINYINT NOT NULL DEFAULT 0,
  ErrMsg VARCHAR(300) NULL DEFAULT '',
  PRIMARY KEY (ID),
  UNIQUE KEY UX_JSChallengeInfo_ChallengeCode (ChallengeCode),
  INDEX IX_JSChallengeInfo_CreatedTime(CreatedTime))
ENGINE = InnoDB;


ALTER TABLE DCS_DataCenter.RawTransaction
ADD JsChallengeID BIGINT UNSIGNED NULL;