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
VALUE (1001, 'Initial IP Details', 'LastTransID', 196616225, NOW());

INSERT IGNORE INTO DCS_Extra.Country(CountryName, CountryCode)
SELECT '-', '-';

INSERT IGNORE INTO DCS_Extra.City(CityName)
SELECT '-';

INSERT IGNORE INTO DCS_Extra.ISP(ISPName)
SELECT '-';

INSERT IGNORE INTO DCS_Extra.Region(RegionName)
SELECT '-';

