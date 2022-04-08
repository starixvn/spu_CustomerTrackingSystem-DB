/*<info serverAlias="DBCTS-bodb02" selectors="bodbSPUNet" isFunction="1" isNested="0"></info>*/

CREATE FUNCTION [dbo].[f_CTS_TWGroupBetting_GetTimeRange] (
	@FromTime DATETIME, 
	@ToTime DATETIME, 
	@Step INT
)	       
RETURNS TABLE
AS
/*
	Created by: 20220308@Harvey.Nguyen
	Task: Calculate TW group betting percent
	DB: DBCTS.bodb02
	Original: 
	
	Revisions:
		- 20220308@Harvey: Initial function [Redmine: #169670]

	Explanation's Param:
		
*/   
RETURN
	SELECT	tally.Fromtime 'FromTime',
			CASE WHEN DATEADD(SECOND, @Step, tally.Fromtime) > @ToTime THEN @ToTime 
			ELSE DATEADD(SECOND, @Step, tally.Fromtime) END AS 'ToTime'
	FROM	(
		SELECT [NoDays] = CASE WHEN ((DATEDIFF(SECOND, @FromTime, @ToTime)) - @Step + 1) < 0 THEN 1 
							ELSE (DATEDIFF(SECOND, @FromTime, @ToTime)) - @Step + 1 END
	) cnt
	CROSS APPLY	(
		SELECT	TOP(cnt.NoDays)
				Fromtime =  DATEADD(SECOND, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) - 1, @FromTime)
		FROM		(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x10(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x100(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x1000(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x10000(n)
	) tally;
GO


