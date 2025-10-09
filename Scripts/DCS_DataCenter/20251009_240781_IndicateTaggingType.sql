/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251009@Jonathan.Doan
Task:	 	Indicate Tagging Type
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20251009@Jonathan.Doan: Created [Redmine ID: #240781]
Reviewer:
*/

USE DCS_DataCenter;

ALTER TABLE RawTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE ProcessedTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE Transaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE Transaction07
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TransFlow TINYINT(1),
ADD COLUMN TaggingType SMALLINT;

