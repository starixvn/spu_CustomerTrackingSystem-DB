USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[f_CTS_TWGroupBetting_GetTimeRange] (
	@FromTime DATETIME, 
	@ToTime DATETIME, 
	@Step INT
)	       
RETURNS TABLE
AS
/*
	Created by: 20220308@Harvey.Nguyen
	Task: Calculate TW group betting percent
	DB: DB061.dbo.bodb02
	Original: 
	
	Revisions:
		- 20220308@Harvey: Initial function [Redmine: #169670]

	Explanation's Param:
		
*/   
RETURN
	SELECT	tally.Fromtime 'FromTime',
		DATEADD(SECOND, @Step, tally.Fromtime) 'ToTime'
	FROM	(
		SELECT	[NoDays] = (DATEDIFF(SECOND, @FromTime, @ToTime)) / 5 + 1
	) cnt
	CROSS APPLY	(
		SELECT	TOP(cnt.NoDays)
				Fromtime =  DATEADD(SECOND, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) - 1, @FromTime)
		FROM		(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x10(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x100(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x1000(n)
	) tally;
GO


