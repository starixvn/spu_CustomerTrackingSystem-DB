/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20220909@Arise.Nguyen
	Task:	 	Update sysparam [Redmine ID: 176992] 	
	DBName:		CTS_DataCenter, CTS_Archive
*/
USE CTS_DataCenter
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES ('117', 'Classification_BySport_History_Archive_BatchSize', 'Classification_BySport_History_Archive_BatchSize', 'BIGINT', '1000'),
       ('118', 'Classification_BySport_History_Archive_LastestID', 'Classification_BySport_History_Archive_LastestID', 'BIGINT', '0'),
       ('119', 'Classification_BySport_History_Archive_TakeDays', 'Classification_BySport_History_Archive_TakeDays', 'BIGINT', '29');



DROP TABLE IF EXISTS CTSCustomerClassification_BySport_History;
CREATE TABLE CTSCustomerClassification_BySport_History (
    ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    CustID BIGINT UNSIGNED DEFAULT NULL,
    CTSCustID BIGINT UNSIGNED DEFAULT NULL,
    SportID SMALLINT UNSIGNED DEFAULT NULL,
    CategoryID SMALLINT UNSIGNED DEFAULT NULL,
    TurnoverRM DECIMAL(20 , 4 ) DEFAULT NULL,
    WinlossRM DECIMAL(20 , 4 ) DEFAULT NULL,
    BetCount BIGINT DEFAULT NULL,
    ActiveDays INT DEFAULT NULL,
    TargetCC SMALLINT DEFAULT NULL,
    FromCategoryID SMALLINT UNSIGNED DEFAULT NULL,
    ActionType TINYINT DEFAULT NULL,
    LastModifiedDate DATETIME DEFAULT NULL,
    LastModifiedBy INT UNSIGNED DEFAULT NULL,
    InsertDate DATETIME DEFAULT NULL,
    PRIMARY KEY (ID),
    KEY IX_CTSCustomerClassification_BySport_History_InsertDate (InsertDate),
    KEY IX_CTSCustomerClassification_BySport_History_CTSCustID (CTSCustID),
    KEY IX_CTSCustomerClassification_BySport_History_CustID_Infor (CustID , SportID , LastModifiedDate)
)  ENGINE=INNODB;
    

DROP TABLE IF EXISTS CTSCustomerClassification_BySport_Log;
CREATE TABLE CTSCustomerClassification_BySport_Log (
    ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    CustID BIGINT UNSIGNED DEFAULT NULL,
    CTSCustID BIGINT UNSIGNED DEFAULT NULL,
    SportID SMALLINT UNSIGNED DEFAULT NULL,
    CategoryID SMALLINT DEFAULT NULL,
    TurnoverRM DECIMAL(20 , 4 ) DEFAULT NULL,
    WinlossRM DECIMAL(20 , 4 ) DEFAULT NULL,
    BetCount BIGINT DEFAULT NULL,
    ActiveDays INT DEFAULT NULL,
    TargetCC SMALLINT DEFAULT NULL,
    FromCategoryID SMALLINT UNSIGNED DEFAULT NULL,
    IsDataChanged TINYINT(1) DEFAULT '0',
    ActionType TINYINT DEFAULT NULL,
    LastModifiedDate DATETIME DEFAULT NULL,
    LastModifiedBy INT UNSIGNED DEFAULT NULL,
    InsertDate DATETIME NOT NULL,
    PRIMARY KEY (ID , InsertDate),
    KEY IX_CTSCustomerClassification_BySport_Log_CustID (CustID)
)  ENGINE=INNODB,  ROW_FORMAT=COMPRESSED
/*!50100 PARTITION BY RANGE (extract(year_month from `InsertDate`))
 (PARTITION pm202209 VALUES LESS THAN (202210) ENGINE = InnoDB,
  PARTITION pm202210 VALUES LESS THAN (202211) ENGINE = InnoDB,
  PARTITION pm202211 VALUES LESS THAN (202212) ENGINE = InnoDB,
  PARTITION pm999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;



/**********************Archive Server****************************/

DROP TABLE IF EXISTS CTSCustomerClassification_BySport_History_Archive;
CREATE TABLE CTSCustomerClassification_BySport_History_Archive (
    ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    HistoryID BIGINT UNSIGNED NOT NULL,
    CustID BIGINT UNSIGNED DEFAULT NULL,
    CTSCustID BIGINT UNSIGNED DEFAULT NULL,
    SportID SMALLINT UNSIGNED DEFAULT NULL,
    CategoryID SMALLINT UNSIGNED DEFAULT NULL,
    TurnoverRM DECIMAL(20 , 4 ) DEFAULT NULL,
    WinlossRM DECIMAL(20 , 4 ) DEFAULT NULL,
    BetCount BIGINT DEFAULT NULL,
    ActiveDays INT DEFAULT NULL,
    TargetCC SMALLINT DEFAULT NULL,
    FromCategoryID SMALLINT UNSIGNED DEFAULT NULL,
    ActionType TINYINT DEFAULT NULL,
    LastModifiedDate DATETIME DEFAULT NULL,
    LastModifiedBy INT UNSIGNED DEFAULT NULL,
    InsertDate DATETIME DEFAULT NULL,
    PRIMARY KEY (ID),
    KEY IX_CTSCustomerClassification_BySport_History_CustID_Infor (CustID)
)  ENGINE=INNODB;

    


USE `CTS_Archive`;
DROP procedure IF EXISTS `CTS_Archive_CustClassification_BySport_History_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Archive_CustClassification_BySport_History_Insert`(
		IN ip_HistoryJson JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220909@Aries.Nguyen
		Task : Archive CTSCustomerClassification_BySport_History
		DB: CTS_Archive 
		Original:

		Revisions:
			- 20220909@Aries.Nguyen:Created  [Redmine ID: #176992] 
            
		Param's Explanation (filtered by):

	*/
	
    INSERT INTO CTS_Archive.CTSCustomerClassification_BySport_History_Archive(HistoryID,CustID,CTSCustID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,FromCategoryID,ActionType,LastModifiedDate,LastModifiedBy,InsertDate)
	SELECT	HistoryID
        ,	CustID 				
		,	CTSCustID 			
		,	SportID 			
		,	CategoryID 			
		,	TurnoverRM 			
		,	WinlossRM 			
		,	BetCount 			
		,	ActiveDays 			
		,	TargetCC 			
		,	FromCategoryID 		
		,	ActionType 			
		,	LastModifiedDate 	
		,	LastModifiedBy 		
		,	InsertDate 	
	FROM JSON_TABLE(
			ip_HistoryJson,
			 "$[*]" COLUMNS(
								HistoryID			BIGINT UNSIGNED 	PATH "$.ID"       
							,	CustID 				BIGINT UNSIGNED		PATH "$.CustID"       
							,	CTSCustID 			BIGINT UNSIGNED		PATH "$.CTSCustID"       
							,	SportID 			SMALLINT UNSIGNED	PATH "$.SportID"       
							,	CategoryID 			SMALLINT UNSIGNED	PATH "$.CategoryID"       
							,	TurnoverRM 			DECIMAL(20 , 4 )	PATH "$.TurnoverRM"       
							,	WinlossRM 			DECIMAL(20 , 4 )	PATH "$.WinlossRM"       
							,	BetCount 			BIGINT				PATH "$.BetCount"       
							,	ActiveDays 			INT					PATH "$.ActiveDays"       
							,	TargetCC 			SMALLINT			PATH "$.TargetCC"       
							,	FromCategoryID 		SMALLINT UNSIGNED	PATH "$.FromCategoryID"       
							,	ActionType 			TINYINT				PATH "$.ActionType"       
							,	LastModifiedDate 	DATETIME			PATH "$.LastModifiedDate"       
							,	LastModifiedBy 		INT UNSIGNED		PATH "$.LastModifiedBy"       
							,	InsertDate 			DATETIME 			PATH "$.InsertDate"    
				)
		   ) AS  tbl;  
END$$

DELIMITER ;
;

