/*<info serverAlias="CTSSMM-SPU_EXEC_SERVICE_HISTORY" executers="fpsWinService" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE CTS_GetSimpleTrigger
AS
/*
	Creator:	20200528@Harvey
	Task:		Get all SIMPLE trigger for monitoring - [Redmine: #124592]
	Database:	DBCTS.bodb02
	
	Revisions:
		- 20181121@Harvey:	Initial - [Redmine: #134790]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_GetSimpleTrigger
		
*/
BEGIN;
	SET NOCOUNT ON;

	SELECT JOB_GROUP 'JobGroup'
		,JOB_NAME 'JobName'
		,qt.TRIGGER_NAME 'TriggerName'
		,NEXT_FIRE_TIME 'NextFireTime'
		,PREV_FIRE_TIME 'PrevFireTime'
		,START_TIME 'StartTime'
		,END_TIME 'EndTime'
		,qst.REPEAT_INTERVAL 'RepeatInterval'
	FROM dbo.QRTZ_TRIGGERS qt WITH (NOLOCK)
		INNER JOIN dbo.QRTZ_SIMPLE_TRIGGERS qst ON qt.TRIGGER_NAME = qst.TRIGGER_NAME
			AND qt.SCHED_NAME = qst.SCHED_NAME
			AND qt.TRIGGER_GROUP = qst.TRIGGER_GROUP
	WHERE TRIGGER_TYPE = 'SIMPLE' 
		AND TRIGGER_STATE <> 'PAUSED'

END;
GO