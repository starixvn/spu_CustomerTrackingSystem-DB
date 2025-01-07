/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
    Creator: 	20241015@Casey.Huynh
    Task:	 	Danger Monitor Tunning [Redmine ID: #207397]
    DBName:		bodb02
*/

USE [bodb02]
GO
create view dbo.[v_danger_custInfo]  WITH SCHEMABINDING
as
select custid, roleid,danger,danger2,danger3,danger4,danger5
from dbo.[custInfo]
where isnull(danger,0)|isnull(danger2,0)|isnull(danger3,0)|isnull(danger4,0)|isnull(danger5,0) <>0 and roleid=1

CREATE UNIQUE CLUSTERED INDEX [IX_dangerlevel] ON [dbo].[v_danger_custInfo]
(
	custid ASC
)
GO