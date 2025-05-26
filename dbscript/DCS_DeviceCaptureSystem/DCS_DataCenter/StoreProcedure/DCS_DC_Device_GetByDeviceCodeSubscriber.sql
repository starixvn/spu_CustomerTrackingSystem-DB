/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Device_GetByDeviceCodeSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Device_GetByDeviceCodeSubscriber`(
		IN ip_SubscriberID	INT
	,	IN ip_DeviceCode	VARCHAR(32)
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20250526@Lando.Vu
	Task : Get Accounts Per Device report
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20250526@Lando.Vu: Created [Redmine ID: 227652]
		
	Param's Explanation (filtered by):

	Example:
		CALL DCS_DC_Device_GetByDeviceCodeSubscriber(@ip_SubscriberID:=8000001,@ip_DeviceCode:='71ea9dc88d474a96b042e0436f9c745f');
	*/
    #========SEARCH BY DeviceCode=====================
    DECLARE lv_DeviceID BIGINT UNSIGNED;
    DECLARE lv_DeviceCode VARCHAR(32);
    DECLARE lv_UserAgentKey VARCHAR(32);
    DECLARE lv_OS VARCHAR(20);
     
	SELECT	dv.DeviceID
		, 	dv.FirstDeviceCode
		, 	dv.UserAgentKey
    INTO lv_DeviceID, lv_DeviceCode, lv_UserAgentKey
    FROM DCS_DataCenter.Device AS dv
	WHERE dv.FirstDeviceCode = ip_DeviceCode
		AND EXISTS (SELECT 1 FROM DCS_DataCenter.Association AS ass WHERE ass.DeviceID = dv.DeviceID AND ass.SubscriberID = ip_SubscriberID);   

    IF lv_UserAgentKey IS NOT NULL THEN	
		SELECT ua.OS
        INTO lv_OS
		FROM  DCS_DataCenter.UserAgent AS ua
		WHERE ua.UserAgentKey = lv_UserAgentKey;
	END IF;
    
	#===========Return Info=============
	SELECT 	lv_DeviceID AS DeviceID 
		, 	lv_DeviceCode AS DeviceCode
        , 	lv_OS AS OS;
END$$
DELIMITER ;
