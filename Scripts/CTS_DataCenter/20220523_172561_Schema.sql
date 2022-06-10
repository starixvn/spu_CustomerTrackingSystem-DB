/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220519@Aries.Nguyen
    Task:	    Disable NAP CM PA flow, add PA directly from CTS [Redmine ID: #172561]
    DBName:		CTS_DataCenter,CTS_Archive
*/

USE CTS_DataCenter;
ALTER TABLE  CustomerCategory ADD  COLUMN IsPAProbation BIT;

ALTER TABLE CTSCustomerClassification 
ADD  COLUMN IsFromTVS BIT DEFAULT 0,
ADD  COLUMN IsFromTW BIT  DEFAULT 0,
ADD  COLUMN IsFromCTS BIT  DEFAULT 0,
ADD  COLUMN IsDirect BIT DEFAULT NULL,
ADD  COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL;

USE CTS_DataCenter;
ALTER TABLE CTSCustomerClassification 
ADD  COLUMN IsFromAI BIT DEFAULT 0;

ALTER TABLE CTSCustomerClassification ADD INDEX IX_CTSCustomerClassification_TVSRequestID(TVSRequestID);

USE CTS_DataCenter
ALTER TABLE  CTSCustomerClassification_History 
ADD COLUMN Remark VARCHAR(500),
ADD COLUMN IsDirect BIT DEFAULT NULL,
ADD COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN  IsFromTVS BIT DEFAULT 0,
ADD COLUMN  IsFromTW BIT DEFAULT 0,
ADD COLUMN  IsFromCTS BIT DEFAULT 0,
ADD COLUMN IsFromAI BIT DEFAULT 0;

ALTER TABLE  CTSCustomerClassification_Log
ADD COLUMN Remark VARCHAR(500),
ADD COLUMN IsDirect BIT DEFAULT NULL,
ADD COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN  IsFromTVS BIT DEFAULT 0,
ADD COLUMN  IsFromTW BIT DEFAULT 0,
ADD COLUMN  IsFromCTS BIT DEFAULT 0,
ADD COLUMN IsFromAI BIT DEFAULT 0;

USE CTS_Archive;
ALTER TABLE  CTSCustomerClassification_History_Archive 
ADD COLUMN Remark VARCHAR(500),
ADD COLUMN IsDirect BIT DEFAULT NULL,
ADD COLUMN TVSRequestID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN  IsFromTVS BIT DEFAULT 0,
ADD COLUMN  IsFromTW BIT DEFAULT 0,
ADD COLUMN  IsFromCTS BIT DEFAULT 0,
ADD COLUMN IsFromAI BIT DEFAULT 0;

USE CTS_DataCenter;
UPDATE CustomerCategory 
SET IsPAProbation = IsProbation;


INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (92, 'ReScanNewMember_LastCTSCustID', 'ReScanNewMember_LastCTSCustID', 'BIGINT', 0);
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (93, 'ReScanNewMember_BatchSize', 'ReScanNewMember_BatchSize', 'INT', 1000);

USE CTS_DataCenter;
CREATE TABLE `CTSCustomerClassification_InputDataLog_V2` (
   `ID` bigint NOT NULL AUTO_INCREMENT,
   `CustID` bigint unsigned NOT NULL,
   `FunctionID` smallint unsigned NOT NULL,
   `InputValue` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
   `CreatedDate` date NOT NULL,
   `CreatedTime` datetime NOT NULL,
   `JsonInputValue` json DEFAULT NULL,
   PRIMARY KEY (`ID`,`CreatedDate`),
   KEY `IXF_CTSCustomerClassification_InputDataLog_CustID` ((cast(json_unquote(json_extract(`JsonInputValue`,'$.CustID')) as unsigned)))
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci
  /*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
 (PARTITION pw202221 VALUES LESS THAN (202222) ENGINE = InnoDB,
  PARTITION pw202222 VALUES LESS THAN (202223) ENGINE = InnoDB,
  PARTITION pw202223 VALUES LESS THAN (202224) ENGINE = InnoDB,
  PARTITION pw202224 VALUES LESS THAN (202225) ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

RENAME TABLE CTSCustomerClassification_InputDataLog TO CTSCustomerClassification_InputDataLog_BK;
RENAME TABLE CTSCustomerClassification_InputDataLog_V2 TO CTSCustomerClassification_InputDataLog;


ALTER TABLE CustomerCategory 
ADD COLUMN DangerLevelType SMALLINT,
ADD COLUMN PAPriority SMALLINT;

UPDATE CustomerCategory
SET    DangerLevelType = CASE WHEN ParentID = 50 OR CategoryID = 50 THEN 2
						 ELSE 1 END 
	,  Priority = CASE WHEN ParentID = 50 AND  RootTaggingID = 13 THEN 20
						 WHEN ParentID = 50 AND  (RootTaggingID IS NULL  OR RootTaggingID != 13) THEN 10
                         ELSE 30 END;

USE CTS_Archive;
CREATE TABLE `CTSLog` (
   `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `LogInfo` json DEFAULT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`,`Created`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
 /*!50100 PARTITION BY RANGE (yearweek(`Created`,0))
 (PARTITION pw202222 VALUES LESS THAN (202223) ENGINE = InnoDB,
  PARTITION pw202223 VALUES LESS THAN (202224) ENGINE = InnoDB,
  PARTITION pw202224 VALUES LESS THAN (202225) ENGINE = InnoDB,
  PARTITION pw202225 VALUES LESS THAN (202226) ENGINE = InnoDB,
  PARTITION pw202226 VALUES LESS THAN (202227) ENGINE = InnoDB,
  PARTITION pw202227 VALUES LESS THAN (202228) ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

USE `CTS_Archive`;
DROP procedure IF EXISTS `CTS_Archive_Log_Insert`;

USE `CTS_Archive`;
DROP procedure IF EXISTS `CTS_Archive`.`CTS_Archive_Log_Insert`;
;

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
                            ,	IsFromTVS 				BOOLEAN 	        PATH IsFromTVS   
			                ,	IsFromTW 				BOOLEAN 	        PATH IsFromTW   
			                ,	IsFromCTS 				BOOLEAN 	        PATH IsFromCTS   
			                ,	IsFromAI 	            BOOLEAN 	        PATH IsFromAI   
				)
		   ) AS  tbl; 
END$$

DELIMITER ;
;