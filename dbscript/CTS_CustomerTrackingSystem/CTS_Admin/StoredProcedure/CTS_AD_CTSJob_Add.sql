/*<info serverAlias="CTSMain-CTS_Admin" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_AD_CTSJob_Add`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_CTSJob_Add`(
	IN ip_JobTrigger	JSON
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

	
	INSERT IGNORE INTO CTS_Admin.CTSJob(JobName, GroupName, JobType, APIUrl, MethodName, Controller, IsActive, IsNew)
	SELECT  js.JobName
		,	js.GroupName
        ,	js.JobType
        ,	js.APIUrl
		,	js.MethodName
		,	js.Controller
		,	js.IsActive
		,	js.IsNew
	FROM JSON_TABLE(ip_JobTrigger,
					 "$[*]" COLUMNS(
								JobName				VARCHAR(300) PATH "$.JobName" 
							,	GroupName			VARCHAR(300) PATH "$.GroupName" 
                            ,	JobType				VARCHAR(300) PATH "$.JobType"
                            ,	APIUrl				VARCHAR(300) PATH "$.ApiUrl" 
							,	MethodName			VARCHAR(300) PATH "$.MethodName" 
							,	Controller			VARCHAR(300) PATH "$.Controller" 
							,	IsActive			TINYINT PATH "$.IsActive"
							,	IsNew				TINYINT PATH "$.IsNew"
						)
				) AS js;
				
	INSERT IGNORE INTO CTS_Admin.CTSTrigger (TriggerName, JobName, TriggerType, IntervalInSecond, CronExpression)
	SELECT  js.TriggerName
		,	js.JobName
        ,	js.TriggerType
        ,	js.IntervalInSecond
		,	js.CronExpression		
	FROM JSON_TABLE(ip_JobTrigger,
					 "$[*]" COLUMNS(
								TriggerName				VARCHAR(300) PATH "$.TriggerName" 
							,	JobName					VARCHAR(300) PATH "$.JobName" 
                            ,	TriggerType				VARCHAR(300) PATH "$.TriggerType"                            
							,	IntervalInSecond		INT PATH "$.IntervalInSecond" 
							,	CronExpression			varchar(300) PATH "$.CronExpression" 										
						)
				) AS js;
				

END$$

DELIMITER ;