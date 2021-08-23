/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20210823@Aries.Nguyen
	Task:	 	Init data and schema [Redmine ID: #160470]
	DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
CREATE TABLE `CTS_DataCenter`.`CustEvidenceAffectedQueueInsert` (
   `ID` 				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `CTSCustID` 			BIGINT UNSIGNED NOT NULL,
   `EvidenceID`		 	SMALLINT,
   `Remark`				VARCHAR(500),
   `CreatedBy`			INT UNSIGNED,
   `Created` 			DATETIME DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB;

CREATE TABLE `CTS_DataCenter`.`CustEvidenceAffectedQueueRemove` (
   `ID` 				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `CTSCustID` 			BIGINT UNSIGNED NOT NULL,
   `EvidenceID`		 	SMALLINT,
   `Created` 			DATETIME DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB;

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (30, 'EffectedEvidence_LastestQueueIDInsert',  'Lastest Queue ID insert affected evidence', 'BIGINT UNSIGNED', '0');

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (31, 'EffectedEvidence_LastestCTSCustIDQueueInsert', 'Lastest association CTSCustID Queue insert', 'BIGINT UNSIGNED', '0');

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (32, 'AffectedEvidence_LastestQueueIDRemove', 'Lastest QueueID Affected Evidence Remove', 'BIGINT UNSIGNED', '0');

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (33, 'AffectedEvidence_LastestLastCTSAssDevID', 'Lastest LastCTSAssDevID to insert affected evidence', 'BIGINT UNSIGNED', '0');

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (34, 'AffectedEvidence_LastestAssociationCTSCustID', 'Lastest association CTSCustID to affected evidence', 'BIGINT UNSIGNED', '0');

