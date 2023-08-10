/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transaction_InitialData_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transaction_InitialData_Get`(
	ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230809@Casey.Huynh
		Task :		Get Transaction IPID
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230809@Casey.Huynh: Created [Redmine ID: 192402]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Transaction_InitialData_Get();
    
    */
    DECLARE lv_LastTransID BIGINT UNSIGNED;
    DECLARE lv_LastCreatedDate DATETIME;   
    
	SELECT st.VValue
    INTO lv_LastTransID
    FROM DCS_Extra.SystemSetting AS st
    WHERE st.ID = 1001;
    
    SELECT st.VValue
    INTO lv_LastCreatedDate
    FROM DCS_Extra.SystemSetting AS st
    WHERE st.ID = 1002;
    
    SELECT 	TransID
		,	IPID
		,	CreatedDate
    FROM DCS_Extra.Transaction07
    WHERE CreatedDate >= lv_LastCreatedDate 
		AND TransID > lv_LastTransID
    LIMIT ip_BatchSize;
	
END$$

DELIMITER ;
