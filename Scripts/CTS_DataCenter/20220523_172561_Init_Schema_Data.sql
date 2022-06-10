/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220519@Aries.Nguyen
    Task:	    Renovate PA process [Redmine ID: #172561]
    DBName:		CTS_Admin, CTS_DataCenter,CTS_Archive
*/

/******************LogType***************************/	
USE CTS_Admin;
INSERT INTO CTS_Admin.LogType(LogTypeID, LogTypeName, LogTypeDescription)
VALUES	(32,'Mark Problem Acccount','Mark Problem Acccount')
	,	(33,'Unmark Problem Acccount','Unmark Problem Acccount');
    
    
/******************SystemParameter***************************/
USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (92, 'ReScanNewMember_LastCTSCustID', 'ReScanNewMember_LastCTSCustID', 'BIGINT', 0);
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (93, 'ReScanNewMember_BatchSize', 'ReScanNewMember_BatchSize', 'INT', 1000);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES (94,'RobotBettingService_LastScannedTime','RobotBettingService_LastScannedTime','DATETIME','2022-09-22 08:00:00.000');	

/******************StaticList***************************/
USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (4,31,'Classification Source Type','Classification Source Type','Problem Account is marked directly','Problem Account is marked directly',31,1,'Problem Account is marked directly',NOW())
	, (4,32,'Classification Source Type','Classification Source Type','Problem Account is affected by Uplines','Problem Account is affected by Uplines',32,1,'Problem Account is affected by Uplines',NOW())
    , (4,33,'Classification Source Type','Classification Source Type','Problem Account is unmarked directly','Problem Account is unmarked directly',33,1,'Problem Account is unmarked directly',NOW())
    , (4,34,'Classification Source Type','Classification Source Type','Unmarking Problem Account is affected by Uplines','Unmarking Problem Account is affected by Uplines',34,1,'Unmarking Problem Account is affected by Uplines',NOW());




/******************CTSCustomerClassification***************************/
USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSCustomerClassification 
ADD  COLUMN IsFromAI BIT DEFAULT 0;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification ADD INDEX IX_CTSCustomerClassification_TVSRequestID(TVSRequestID);


/******************CustomerCategory***************************/
USE CTS_DataCenter;
ALTER TABLE  CTS_DataCenter.CustomerCategory 
ADD  COLUMN IsPAProbation BIT,
ADD COLUMN DangerLevelType SMALLINT,
ADD COLUMN PAPriority SMALLINT;

USE CTS_DataCenter;
UPDATE CTS_DataCenter.CustomerCategory 
SET IsPAProbation = IsProbation;

UPDATE CTS_DataCenter.CustomerCategory
SET    DangerLevelType = CASE WHEN ParentID = 50 OR CategoryID = 50 THEN 2
						 ELSE 1 END 
	,  Priority = CASE WHEN ParentID = 50 AND  RootTaggingID = 13 THEN 20
						 WHEN ParentID = 50 AND  (RootTaggingID IS NULL  OR RootTaggingID != 13) THEN 10
                         ELSE 30 END;

UPDATE CTS_DataCenter.CustomerCategory SET ReasonID = 36 where CategoryID = 61;
UPDATE CTS_DataCenter.CustomerCategory SET ReasonID = 229 where CategoryID = 57;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 163 where CategoryID = 163;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 164 where CategoryID = 164;

/******************CTSCustomerClassification_History***************************/
USE CTS_DataCenter;
ALTER TABLE  CTS_DataCenter.CTSCustomerClassification_History 
ADD COLUMN Remark VARCHAR(500),
ADD COLUMN IsDirect BIT DEFAULT NULL,
ADD COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN  IsFromTVS BIT DEFAULT 0,
ADD COLUMN  IsFromTW BIT DEFAULT 0,
ADD COLUMN  IsFromCTS BIT DEFAULT 0,
ADD COLUMN IsFromAI BIT DEFAULT 0;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History ADD INDEX IX_CTSCustomerClassification_TVSRequestID(TVSRequestID);

/******************CTSCustomerClassification_Log***************************/
USE CTS_DataCenter;
ALTER TABLE  CTS_DataCenter.CTSCustomerClassification_Log
ADD COLUMN Remark VARCHAR(500),
ADD COLUMN IsDirect BIT DEFAULT NULL,
ADD COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN  IsFromTVS BIT DEFAULT 0,
ADD COLUMN  IsFromTW BIT DEFAULT 0,
ADD COLUMN  IsFromCTS BIT DEFAULT 0,
ADD COLUMN IsFromAI BIT DEFAULT 0;


/******************CTSCustomerClassificationVVIP***************************/
USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSCustomerClassificationVVIP
ADD COLUMN IsDirect TINYINT(1);


/******************CTSCustomerClassificationQueue***************************/
USE CTS_DataCenter;
CREATE TABLE CTSCustomerClassificationQueue (
   ID bigint unsigned NOT NULL AUTO_INCREMENT,
   CTSCustID bigint unsigned DEFAULT NULL,
   CustID bigint unsigned DEFAULT NULL,
   RoleID tinyint DEFAULT NULL,
   SubscriberID int unsigned DEFAULT NULL,
   CreatedBy bigint unsigned DEFAULT NULL,
   Remark varchar(300) COLLATE utf8_unicode_ci DEFAULT NULL,
   CategoryGroup int DEFAULT NULL,
   CategoryID smallint unsigned DEFAULT NULL,
   LastDownlineCTSCustID bigint unsigned DEFAULT NULL,
   ActionType tinyint DEFAULT NULL COMMENT '1: INSERT VVIP, 2:Remove VVIP, 3:INSERT PA, 4: UNMARK PA',
   InsertTime datetime(3) DEFAULT NULL,
   IsExceptDirectDownline tinyint(1) DEFAULT NULL,
   IsFromTVS tinyint(1) DEFAULT '0',
   IsFromTW tinyint(1) DEFAULT '0',
   IsFromCTS tinyint(1) DEFAULT '0',
   IsDirect tinyint(1) DEFAULT NULL,
   TVSRequestID bigint unsigned DEFAULT NULL,
   PRIMARY KEY (ID),
   KEY IX_Temp_Customer_CustID (CustID),
   KEY IX_Temp_Customer_TVSRequestID (TVSRequestID),
   KEY IX_Temp_Customer_CTSCustID (CTSCustID)
 ) ENGINE=InnoDB;
 
 
 /******************CTSCustomerClassificationOldPA***************************/
 USE CTS_DataCenter;
 CREATE TABLE CTSCustomerClassificationOldPA (
   CustID bigint unsigned NOT NULL,
   CTSCustID bigint unsigned DEFAULT NULL,
   SubscriberID int unsigned DEFAULT NULL,
   SportGroupID smallint unsigned NOT NULL,
   CategoryID smallint unsigned NOT NULL,
   Remark varchar(500) DEFAULT NULL,
   CreatedDate datetime DEFAULT NULL,
   CreatedBy int DEFAULT NULL,
   LastModifiedDate datetime DEFAULT NULL,
   LastModifiedBy int unsigned DEFAULT NULL,
   LastScannedDate date DEFAULT NULL,
   IsFromTVS tinyint(1) DEFAULT '0',
   IsFromTW tinyint(1) DEFAULT '0',
   IsFromCTS tinyint(1) DEFAULT '0',
   IsDirect tinyint(1) DEFAULT NULL,
   InsertTime datetime(3) DEFAULT NULL,
   TVSRequestID bigint unsigned DEFAULT NULL,
   IsFromAI bit(1) DEFAULT b'0',
   PRIMARY KEY (CustID,SportGroupID,CategoryID),
   KEY IX_CTSCustomerClassificationOldPA_CTSCustID (CTSCustID),
   KEY IX_CTSCustomerClassificationOldPA_TVSRequestID (TVSRequestID)
 ) ENGINE=InnoDB;
 
 
  /******************TVSVoidRequest_History***************************/
 USE CTS_DataCenter;
 CREATE TABLE TVSVoidRequest_History (
  ID 				bigint unsigned auto_increment primary key,
  TVSRequestID 	bigint unsigned DEFAULT NULL,
  CustIDs 		VARCHAR(2000),
  ReasonID 		int DEFAULT NULL,
  CreatedBy 		int DEFAULT NULL,
  CreatedDate 	date DEFAULT NULL,
  KEY IX_TVSVoidRequest_History_CreatedDate (CreatedDate),
  KEY IX_TVSVoidRequest_History_ReasonID (ReasonID)
) ENGINE=InnoDB;


  /******************CTSCustomerClassification_InputDataLog_V2***************************/
USE CTS_DataCenter;
CREATE TABLE CTSCustomerClassification_InputDataLog_V2 (
   ID bigint NOT NULL AUTO_INCREMENT,
   CustID bigint unsigned NOT NULL,
   FunctionID smallint unsigned NOT NULL,
   InputValue varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
   CreatedDate date NOT NULL,
   CreatedTime datetime NOT NULL,
   JsonInputValue json DEFAULT NULL,
   PRIMARY KEY (ID,CreatedDate),
   KEY IXF_CTSCustomerClassification_InputDataLog_CustID ((cast(json_unquote(json_extract(JsonInputValue,'$.CustID')) as unsigned)))
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci
  /*!50100 PARTITION BY RANGE (yearweek(CreatedDate,0))
 (PARTITION pw202221 VALUES LESS THAN (202222) ENGINE = InnoDB,
  PARTITION pw202222 VALUES LESS THAN (202223) ENGINE = InnoDB,
  PARTITION pw202223 VALUES LESS THAN (202224) ENGINE = InnoDB,
  PARTITION pw202224 VALUES LESS THAN (202225) ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

RENAME TABLE CTS_DataCenter.CTSCustomerClassification_InputDataLog TO CTSCustomerClassification_InputDataLog_BK;
RENAME TABLE CTS_DataCenter.CTSCustomerClassification_InputDataLog_V2 TO CTSCustomerClassification_InputDataLog;



  /******************CTS_Archive CTSCustomerClassification_History_Archive***************************/
USE CTS_Archive;
ALTER TABLE  CTS_Archive.CTSCustomerClassification_History_Archive 
ADD COLUMN Remark VARCHAR(500),
ADD COLUMN IsDirect BIT DEFAULT NULL,
ADD COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN  IsFromTVS BIT DEFAULT 0,
ADD COLUMN  IsFromTW BIT DEFAULT 0,
ADD COLUMN  IsFromCTS BIT DEFAULT 0,
ADD COLUMN IsFromAI BIT DEFAULT 0;


  /******************CTS_Archive CTSLog***************************/
USE CTS_Archive;
CREATE TABLE CTSLog (
   ID bigint unsigned NOT NULL AUTO_INCREMENT,
   LogInfo json DEFAULT NULL,
   Created datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (ID,Created)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
 /*!50100 PARTITION BY RANGE (yearweek(Created,0))
 (PARTITION pw202222 VALUES LESS THAN (202223) ENGINE = InnoDB,
  PARTITION pw202223 VALUES LESS THAN (202224) ENGINE = InnoDB,
  PARTITION pw202224 VALUES LESS THAN (202225) ENGINE = InnoDB,
  PARTITION pw202225 VALUES LESS THAN (202226) ENGINE = InnoDB,
  PARTITION pw202226 VALUES LESS THAN (202227) ENGINE = InnoDB,
  PARTITION pw202227 VALUES LESS THAN (202228) ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;


  /******************CTS_Archive CTS_Archive_Log_Insert***************************/

USE `CTS_Archive`;
DROP procedure IF EXISTS `CTS_Archive_Log_Insert`;


DELIMITER $$
USE `CTS_Archive`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Archive_Log_Insert`(
		ip_LogInfo 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220523@Aries.Nguyen
		Task:		Write Log
		DB:			CTS_Archive
        
		Revisions:
			- 	20220523@Aries.Nguyen: Created [Redmine ID: 172561]
            
		Param's Explanation (filtered by):
			-	CALL CTS_Archive.CTS_Archive_Log_Insert ('{"message":"write log","spName":"CTS_DC_CustClassification_PA_InsertRobot","param":"1,2,3,4"}');

	*/	
    INSERT INTO CTS_Archive.CTSLog(LogInfo)
    VALUES (ip_LogInfo); 
END$$

DELIMITER ;
;


  /******************CTS_Archive CTS_Archive_Log_Insert***************************/

USE `CTS_Archive`;
DROP procedure IF EXISTS `CTS_Archive_CustClassification_History_Insert`;

DELIMITER $$
USE `CTS_Archive`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Archive_CustClassification_History_Insert`(
		IN ip_HistoryJson JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20210826@Aries.Nguyen
		Task : Archive CTSCustomerClassification_History
		DB: CTS_Archive 
		Original:

		Revisions:
			- 20201006@Aries.Nguyen:Created  [Redmine ID: #160758] 
            
		Param's Explanation (filtered by):

	*/
	
    INSERT INTO CTS_Archive.CTSCustomerClassification_History_Archive(
			HistoryID
        ,	CustID
        ,	CTSCustID
        ,	SportGroupID
        ,	CategoryID
        ,	TurnoverRM
        ,	WinlossRM
        ,	BetCount
        ,	ActiveDays
        ,	RobotCounter
        ,	ProbationPeriodWinloss
        ,	TargetCC
        ,	SourceTypeID
		,	FromCategoryID 			
        ,	ToCategoryID 			
        ,	IsAppliedCC 			
        ,	IsDataChanged 			
        ,	ActionType 				
        ,	IsAuto 					
        ,	LastModifiedDate 		
        ,	LastModifiedBy 			
        ,	InsertDate 				
        ,	TaggingType 			
        ,	TargetDangerLevel1 		
        ,	IsAppliedDangerLevel1 	
        ,	TWGroupBettingRate 		
        ,	TWTicketRejectRate 		
        ,	TWBetCount 				
        ,	TWDesktopUsageRate   
     	,	Remark
        ,   IsDirect
        ,   TVSRequestID
        ,	IsFromTVS 				 
		,	IsFromTW 				
		,	IsFromCTS 				
		,	IsFromAI 	
	)
	SELECT	HistoryID
        ,	CustID
        ,	CTSCustID
        ,	SportGroupID
        ,	CategoryID
        ,	TurnoverRM
        ,	WinlossRM
        ,	BetCount
        ,	ActiveDays
        ,	RobotCounter
        ,	ProbationPeriodWinloss
        ,	TargetCC
        ,	SourceTypeID
		,	FromCategoryID 			
        ,	ToCategoryID 			
        ,	IsAppliedCC 			
        ,	IsDataChanged 			
        ,	ActionType 				
        ,	IsAuto 					
        ,	LastModifiedDate 		
        ,	LastModifiedBy 			
        ,	InsertDate 				
        ,	TaggingType 			
        ,	TargetDangerLevel1 		
        ,	IsAppliedDangerLevel1 	
        ,	TWGroupBettingRate 		
        ,	TWTicketRejectRate 		
        ,	TWBetCount 				
        ,	TWDesktopUsageRate  
        ,	Remark
        ,   IsDirect
        ,   TVSRequestID
        ,	IsFromTVS 				 
		,	IsFromTW 				
		,	IsFromCTS 				
		,	IsFromAI 	
	FROM JSON_TABLE(
			ip_HistoryJson,
			 "$[*]" COLUMNS(
								HistoryID				BIGINT UNSIGNED 	PATH "$.ID"       
							,	CustID					BIGINT UNSIGNED 	PATH "$.CustID"   
							,	CTSCustID				BIGINT UNSIGNED 	PATH "$.CTSCustID"
							,	SportGroupID			SMALLINT UNSIGNED	PATH "$.SportGroupID"
							,	CategoryID				SMALLINT			PATH "$.CategoryID"
							,	TurnoverRM				DECIMAL(20 , 4 )	PATH "$.TurnoverRM"
							,	WinlossRM				DECIMAL(20 , 4 ) 	PATH "$.WinlossRM"
							,	BetCount				BIGINT 				PATH "$.BetCount"
                            ,	ActiveDays				INT					PATH "$.ActiveDays"
                            ,	RobotCounter			DECIMAL(20 , 4 )	PATH "$.RobotCounter"
							,	ProbationPeriodWinloss	DECIMAL(20 , 4 ) 	PATH "$.ProbationPeriodWinloss"
							,	TargetCC				SMALLINT 			PATH "$.TargetCC"
                            ,	SourceTypeID			SMALLINT UNSIGNED	PATH "$.SourceTypeID"
							,	FromCategoryID 			SMALLINT UNSIGNED 	PATH "$.FromCategoryID"
							,	ToCategoryID 			SMALLINT UNSIGNED 	PATH "$.ToCategoryID"
							,	IsAppliedCC 			BIT(1) 				PATH "$.IsAppliedCC"
							,	IsDataChanged 			BIT(1) 				PATH "$.IsDataChanged"
							,	ActionType 				TINYINT 			PATH "$.ActionType"
							,	IsAuto 					BIT(1) 				PATH "$.IsAuto"
							,	LastModifiedDate 		DATETIME 			PATH "$.LastModifiedDate"
							,	LastModifiedBy 			INT UNSIGNED 		PATH "$.LastModifiedBy"
							,	InsertDate 				DATETIME  			PATH "$.InsertDate"
							,	TaggingType 			SMALLINT  			PATH "$.TaggingType"
							,	TargetDangerLevel1 		SMALLINT  			PATH "$.TargetDangerLevel1"
							,	IsAppliedDangerLevel1 	BIT(1)  			PATH "$.IsAppliedDangerLevel1"
							,	TWGroupBettingRate 		DECIMAL(10 , 4 )  	PATH "$.TWGroupBettingRate"
							,	TWTicketRejectRate 		DECIMAL(10 , 4 )  	PATH "$.TWTicketRejectRate"
							,	TWBetCount 				BIGINT  			PATH "$.TWBetCount"
							,	TWDesktopUsageRate		DECIMAL(10 , 4 ) 	PATH "$.TWDesktopUsageRate"
                            ,	Remark		            VARCHAR(500) 		PATH "$.Remark"
                            ,   IsDirect                BOOLEAN             PATH "$.IsDirect"
                            ,   TVSRequestID            BIGINT UNSIGNED 	PATH "$.TVSRequestID"   
                            ,	IsFromTVS 				BOOLEAN 	        PATH "$.IsFromTVS"
			                ,	IsFromTW 				BOOLEAN 	        PATH "$.IsFromTW"  
			                ,	IsFromCTS 				BOOLEAN 	        PATH "$.IsFromCTS"   
			                ,	IsFromAI 	            BOOLEAN 	        PATH "$.IsFromAI"  
				)
		   ) AS  tbl; 
END$$

DELIMITER ;
;


