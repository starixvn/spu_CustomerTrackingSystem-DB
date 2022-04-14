/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220323@Aries.Nguyen
    Task:	 	Allow Unmark and Update on PA Management Function [Redmine ID: #170135]
    DBName:		CTS_DataCenter
*/
/*1. Get Evidence NAP. Run on Replica(185)*/
SELECT * 
FROM CTS_DataCenter.CustEvidence
WHERE CTSCustID > 0 AND Level = 0 AND Remark = 'Add from Problem Account Management';

/*2. Export csv*/

/*3. Import Data.  Run on Master(58)*/
USE CTS_Adhoc;
DROP TABLE IF EXISTS CustEvidence_NAP;
CREATE TABLE `CustEvidence_NAP` (
   `CustEvidID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `CTSCustID` bigint unsigned NOT NULL,
   `EvidenceID` smallint NOT NULL,
   `Remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
   `Level` tinyint NOT NULL COMMENT 'Level 1 - 2',
   `FromCustID` bigint unsigned NOT NULL,
   `CreatedDate` datetime NOT NULL,
   `CreatedBy` int NOT NULL,
   PRIMARY KEY (`CTSCustID`,`FromCustID`,`EvidenceID`),
   UNIQUE KEY `UX_CustEvidence_CustEvidID` (`CustEvidID`)
 ) ENGINE=InnoDB;

 SET GLOBAL local_infile = 'OFF';

LOAD DATA LOCAL INFILE  '{Path}/Evidence_Nap.csv'
INTO TABLE CTS_Adhoc.CustEvidence_NAP
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/*4. Update data.  Run on Master(58)*/

UPDATE CTS_DataCenter.CustEvidence AS ev
SET ev.SourceType = 1
WHERE EXISTS (SELECT 1 FROM CTS_Adhoc.CustEvidence_NAP AS tmp WHERE tmp.CustEvidID =  ev.CustEvidID);