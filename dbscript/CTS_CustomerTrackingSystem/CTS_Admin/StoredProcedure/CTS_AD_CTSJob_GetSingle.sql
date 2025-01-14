/*<info serverAlias="CTSMain-CTS_Admin" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_AD_CTSJob_GetSingle`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_CTSJob_GetSingle`(
		IN ip_JobName 		VARCHAR(300)
	 ,	IN ip_GroupName 	VARCHAR(300)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20250102@Adam.Tran
		Task:		CTS - Main Service - Extend Functions Scheduler manager [Redmine ID: 215328]
		DB:			CTS_Admin
		Original:

		Revisions: 
			- 20250102@Adam.Tran:   Created
			
		Param's Explanation (filtered by):
	*/
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Job;
    CREATE TEMPORARY TABLE Temp_Job(		
			JobName   			varchar(300)
        ,	GroupName   		varchar(300)
		,	JobType				varchar(300)
		,	APIUrl				varchar(500)
		,	MethodName			varchar(300)
		,	Controller			varchar(300)
		,	IsActive			TINYINT
		,	IsNew				TINYINT
		,	PRIMARY KEY (JobName, GroupName)
    );
	
	INSERT INTO Temp_Job(JobName, GroupName, JobType, APIUrl, MethodName, Controller, IsActive, IsNew)
    SELECT	j.JobName
			, j.GroupName
			, j.JobType
			, j.APIUrl
			, j.MethodName
			, j.Controller
			, j.IsActive
			, j.IsNew
	FROM 	CTS_Admin.CTSJob AS j
	WHERE	j.JobName = ip_JobName AND j.GroupName = ip_GroupName;
	
	SELECT	j.JobName
			, j.GroupName
			, j.JobType
			, j.APIUrl
			, j.MethodName
			, j.Controller
			, j.IsActive
			, j.IsNew
	FROM 	Temp_Job AS j;
	
	SELECT 	tr.TriggerName
			, tr.JobName
			, tr.TriggerType
			, tr.IntervalInSecond
			, tr.CronExpression				
	FROM 	CTS_Admin.CTSTrigger as tr
		INNER JOIN Temp_Job AS j ON tr.JobName = j.JobName;

END$$

DELIMITER ;