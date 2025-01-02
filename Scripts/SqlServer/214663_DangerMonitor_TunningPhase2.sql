/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Creator: 	20241015@Casey.Huynh
    Task:	 	Danger Monitor Tunning [Redmine ID: #207397]
    DBName:		bodb02
*/

USE [bodb02]
GO

CREATE VIEW dbo.[v_danger_custInfo]  WITH SCHEMABINDING
AS
SELECT custid, roleid,danger,danger2,danger3,danger4,danger5
FROM dbo.[custInfo]