/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_CustomerEsportAutoSuspendStatus_Get] 
		 @custId				INT
AS
/*
	Created: 20192012@HarveyNguyen
	Task : GET Auto suspend status
	DB: [bodb02]
	Original:

	Revisions:
		- 20191220@Harvey:	Initial - [Redmine: #125862]

	Param's Explanation:

	EXEC CTS_CustomerEsportAutoSuspendStatus_Get 32879089
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@sportType			INT	= 43	-- esport
			,@esportAutoSuspend BIT = 0;

	CREATE TABLE #AllSuspendStatus (
		CustId INT
		,AutoSuspendLive BIT
		,AutoSuspendNonLive BIT
		);

	INSERT INTO #AllSuspendStatus (
		CustId
		,AutoSuspendLive
		,AutoSuspendNonLive
		)
	SELECT @custId 'CustId'
		,fnGetAutoSuspendForLive.IsVRAutoSuspend 'AutoSuspendLive'
		,fnGetAutoSuspendForNonLive.IsVRAutoSuspend 'AutoSuspendNonLive'
	FROM VRSettingHierarchy h WITH (NOLOCK)
		LEFT JOIN VRLeagueGroup lg WITH (NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
		LEFT JOIN VRLeagueGroupMapping lm WITH (NOLOCK) ON lg.GroupID = lm.VRLeagueGroupID
		CROSS APPLY f_GetVRAutosuspendStatus(@custId, h.SportType, h.BetType, lm.LeagueGroupID, 1) AS fnGetAutoSuspendForLive
		CROSS APPLY f_GetVRAutosuspendStatus(@custId, h.SportType, h.BetType, lm.LeagueGroupID, 0) AS fnGetAutoSuspendForNonLive
	WHERE h.SportType = @sportType
		AND h.bettype <> - 1;

	IF EXISTS (
			SELECT 1
			FROM #AllSuspendStatus
			WHERE AutoSuspendLive = 1
				OR AutoSuspendNonLive = 1
			)
		SET @esportAutoSuspend = 1;

	SELECT @custId 'CustId'
		,@esportAutoSuspend 'EsportAutoSuspendStatus';

	DROP TABLE #AllSuspendStatus;

END;
GO
