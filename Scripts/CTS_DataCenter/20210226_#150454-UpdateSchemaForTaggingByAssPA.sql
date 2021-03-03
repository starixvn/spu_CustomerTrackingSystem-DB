/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210226@Irena.Vo
	Task: 	 150454 - Update schema for Tagging By Association With PA [Redmine ID: #150454]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210226@Irena.Vo]: Add new table: TaggingExclusion, TaggingToCategory. Add new column TaggingType: CTSCustomerClassification_History.
*/
USE CTS_DataCenter;

/* Add new table TaggingExclusion */
CREATE TABLE `TaggingExclusion` (
	`CustID` BIGINT	UNSIGNED NOT NULL PRIMARY KEY,
 	`CreatedTime` DATETIME NOT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

/* Add new table TaggingToCategory */


/* Add new column TaggingType */
ALTER TABLE `CTSCustomerClassification_History`
ADD COLUMN	`TaggingType` SMALLINT DEFAULT 1, ALGORITHM=INSTANT;