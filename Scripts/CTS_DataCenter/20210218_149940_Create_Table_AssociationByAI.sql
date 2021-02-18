/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210105@Aries.Nguyen
	Task: 	 Creeate table [Redmine ID: #149940]
	DB: 	 CTS_DataCenter
*/

USE CTS_DataCenter;
CREATE TABLE `AssociationByAI` (
   `FromCustID` BIGINT UNSIGNED NOT NULL,
   `ToCustID` BIGINT UNSIGNED NOT NULL,
   `CreatedDate` DATE DEFAULT NULL,
   PRIMARY KEY (`FromCustID`,`ToCustID`),
   KEY `IX_AssociationByAI_ToCustID` (`ToCustID`),
   KEY `IX_AssociationByAI_CreatedDate` (`CreatedDate`)
 ) ENGINE=InnoDB;
