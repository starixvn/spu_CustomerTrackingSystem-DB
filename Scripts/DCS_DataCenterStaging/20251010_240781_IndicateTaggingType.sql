/*<info serverAlias="CTSMain-DCS_DataCenterStaging" databaseType="2"></info>*/
/*
Creator:	20251010@Jonathan.Doan
Task:	 	AI Power Device Fingerprint
Server:  	Master
DBName:		DCS_DataCenterStaging

Revisions: 
		- 20251010@Jonathan.Doan: Created [Redmine ID: #240781]
Reviewer:
*/

USE DCS_DataCenterStaging;

ALTER TABLE RawTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;