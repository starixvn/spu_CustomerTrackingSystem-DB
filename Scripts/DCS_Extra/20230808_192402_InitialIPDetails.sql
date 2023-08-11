/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
Creator:	20230808@Casey.Huynh
Task:	 	Initial IP Details
Server:  	Master
DBName:		DCS_Extra

Revisions: 
		- 20230808@Casey.Huynh: Created [Redmine ID: #192402]
Reviewer:
*/
USE DCS_Extra;
INSERT INTO SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUE (1001, 'Initial IP Details', 'LastTransID', 0, NOW())
	, (1002, 'Initial IP Details', 'LastPartitionName', 'pw202332', NOW());

INSERT IGNORE INTO DCS_Extra.Country(CountryName, CountryCode)
SELECT '-', '-';

INSERT IGNORE INTO DCS_Extra.City(CityName)
SELECT '-';

INSERT IGNORE INTO DCS_Extra.ISP(ISPName)
SELECT '-';

INSERT IGNORE INTO DCS_Extra.Region(RegionName)
SELECT '-';


UPDATE DCS_Extra.SystemSetting
set VValue = (select max(TransID) + 1 FROM DCS_Extra.Transaction07)
WHERE ID = 1001;

UPDATE DCS_Extra.SystemSetting
set VName = 'LastPartitionName'
,	VValue = 'pw202332'
WHERE ID = 1002;