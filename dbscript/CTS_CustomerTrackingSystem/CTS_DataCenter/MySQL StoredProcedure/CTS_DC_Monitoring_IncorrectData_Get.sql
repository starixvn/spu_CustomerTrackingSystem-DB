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
            - 20241213@Jonas.Huynh: Missing Customer [Redmine ID: 214157]
            
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_IncorrectData_Get ();

	*/
    DECLARE CONST_BATCHSIZE			SMALLINT DEFAULT 5000;
    DECLARE lv_ToLastTime 			DATE DEFAULT DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 MINUTE);
    DECLARE lv_LastScanID 			BIGINT UNSIGNED;
    DECLARE lv_CountTimes 			TINYINT UNSIGNED;
    DECLARE lv_LastScanMissing 		BIGINT UNSIGNED;
       
    SELECT ParameterValue
	INTO lv_LastScanID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 151; 
    
    SELECT 		a.ID
			,	a.IssueTypeID	
			,	a.CustID
            ,	a.`Value`
            ,	a.TrackingInfo
            ,	a.CreatedTime
            ,	s.ItemID
            ,	a.IsResolved
            ,	CASE WHEN s.ItemID IS NOT NULL THEN TRUE ELSE FALSE END AS IsIssueTypeValid
    FROM CTS_DataCenter.JobMonitoring_IncorrectData AS a
		LEFT JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 20 AND s.ItemID = a.IssueTypeID
	WHERE ID > lv_LastScanID
		AND CreatedTime <= lv_ToLastTime
    ORDER BY ID ASC
    LIMIT CONST_BATCHSIZE;   
    
END$$
DELIMITER ;