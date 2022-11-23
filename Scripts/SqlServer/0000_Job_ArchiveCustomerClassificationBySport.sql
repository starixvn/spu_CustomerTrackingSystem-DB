/*
	Created: 20221123@Jonas.Huynh
	Task : Archive Customer Classification BySport Job
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20201123@Jonas.Huynh: Created Job

	Param's Explanation:
	Example: 
*/
USE msdb
GO

BEGIN TRY
    BEGIN TRAN

    DECLARE @jobId BINARY(16)

    --Add job
    EXEC dbo.sp_add_job 
		@job_name=N'SPU - Archive Customer Classification By Sport Job',
		@description=N'Archive data table CustomerClassification_BySport',
		@enabled=1,
		@job_id=@jobId OUTPUT

    --Add step to job
    EXEC dbo.sp_add_jobstep 
			@job_id = @jobId, 
			@step_name = N'Execute SP', 
            @step_id=1, 
            @subsystem=N'TSQL', 
            @command=N'USE [bodb_VR2Model] 
					   GO 
					   EXEC	[dbo].[CTS_NormalAccountsClassification_BySport_Archive]
					   GO', 
            @on_success_action = 1, 
            @flags=0,
			@database_name=N'bodb_VR2Model'

    --Add schedule to job
    EXEC dbo.sp_add_jobschedule 
			@job_id=@jobId, 
			@name=N'09:00 PM GMT-4, every day', 
			@enabled=1,
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=1, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=NULL, 
            @active_end_date=99991231, 
            @active_start_time=210000, 
            @active_end_time=235959

	--Add schedule to job server
	EXEC dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

    COMMIT TRAN
END TRY
BEGIN CATCH
    SELECT ERROR_Message(), ERROR_Line();
    ROLLBACK TRAN
END CATCH