/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[CTS_TWGroupBetting_GetRules]
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate Group betting ticket
	DB	 : bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket [Redmine ID: #169671]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_GetRules]
*/
BEGIN
	SET NOCOUNT ON;

	SELECT RuleId
		,RuleName
		,LimitSecond
	FROM SPU_GroupBettingRule WITH (NOLOCK);
END