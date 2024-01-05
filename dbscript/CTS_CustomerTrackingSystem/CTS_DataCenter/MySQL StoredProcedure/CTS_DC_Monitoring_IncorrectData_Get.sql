/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_IncorrectData_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_IncorrectData_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240102@Jonas.Huynh
		Task:		Enhance Monitoring Job [Redmine ID: 197999]
		DB:			CTS_DataCenter
		Original:

		Revisions:
            - 20240102@Jonas.Huynh: Creator [Redmine ID: 197999]
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_IncorrectData_Get ();

	*/
    DECLARE CONST_BATCHSIZE			SMALLINT DEFAULT 5000;
    
    DECLARE lv_LastScanID 		BIGINT UNSIGNED;
       
    SELECT ParameterValue
	INTO lv_LastScanID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 151; 
   
    SELECT 		ID
			,	IssueTypeID	
			,	CustID
            ,	`Value`
            ,	TrackingInfo
            ,	CreatedTime
    FROM CTS_DataCenter.JobMonitoring_IncorrectData
	WHERE ID > lv_LastScanID
    ORDER BY ID ASC
    LIMIT CONST_BATCHSIZE;   
    
END$$
DELIMITER ;