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
ADD  COLUMN IsFromPAM BIT  DEFAULT 0,
ADD  COLUMN IsDirect BIT DEFAULT NULL;

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

