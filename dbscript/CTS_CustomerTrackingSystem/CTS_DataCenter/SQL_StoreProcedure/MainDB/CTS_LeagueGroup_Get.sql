/*<info serverAlias="DBCTS-bodb02" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_LeagueGroup_Get]		
		@SportGroup	SMALLINT
	,	@SportType	INT

AS
/*
	Created: 20240702@Casey.Huynh
	Task : CTS_LeagueGroup_Get 
	DB	 : bodb02

	Revisions:
		- 20240702@Casey.Huynh:	Create [Redmine ID: #196361]		
		- 20240322@Vitoria.Le:	Danger Page Main - Get List SportType,Bettype which they ared seperated by LeagueGroupID [Redmine ID: #201380]		

	Params Explaination:	
		
		- SportGroup:
			1: NOT Saba Virtual Sport
			2: Saba Virtual Sport

		- SportType IN (1,2,5,6,7,8,9,18,43,50):
			1: 	Soccer | 2: Basketball | 5: Tennis
			6: 	Volleyball | 7: Snooker/Pool	| 8: Baseball
			9: 	Badminton | 18: Table Tennis | 43: E-Sports
			50: Cricket
			....
			
	Example:
		EXEC CTS_LeagueGroup_Get @SportGroup=1, @Sporttype='2'
		EXEC CTS_LeagueGroup_Get @SportGroup=2, @Sporttype=NULL
*/
BEGIN
	SET NOCOUNT ON;
		
	IF @SportGroup = 1  
	BEGIN
		SELECT lg.GroupID, lg.GroupName, lg.SportType
		FROM bodb02.dbo.LeagueGroup AS lg WITH(NOLOCK)
		WHERE lg.IsActive = 1
			AND (lg.Sporttype = 0 OR lg.SportType = @SportType)
			AND lg.GroupID NOT IN (42,74,108,113,122,151)	
		ORDER BY lg.GroupID;
	END
	ELSE --Saba LeagueGroup
	BEGIN
		SELECT lg.GroupID, lg.GroupName, lg.SportType
		FROM bodb02.dbo.LeagueGroup AS lg WITH(NOLOCK)
		WHERE lg.IsActive = 1
			AND lg.GroupID IN (42,74,108,113,122,151)					
		ORDER BY lg.GroupID;
	END
END