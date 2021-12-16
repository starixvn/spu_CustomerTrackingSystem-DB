/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Profile_GetLoginStats`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Profile_GetLoginStats`(
		IN ip_CTSCustID BIGINT UNSIGNED
	,	IN ip_FromDate	DATE
    ,	IN ip_ToDate	DATE
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211214@Aries.Nguyen	
		Task :		Enrich the information on customer profile
		DB:			CTS_DataCenter
		
		Revisions:
			- 20211214@Aries.Nguyen: Created [Redmine ID: #165105]

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Profile_GetLoginStats(200);
	*/
    DECLARE lv_AccountID 				BIGINT UNSIGNED;
	DECLARE lv_Count_Device_Desktop 	INT;
    DECLARE lv_Count_Device_Mobile 		INT;
    DECLARE lv_Count_Device_Others 		INT;
    DECLARE lv_Count_Login				INT;
    DECLARE lv_Count_IP					INT;
    DECLARE lv_Count_Device				INT;
    
    SELECT AccountID 
    INTO lv_AccountID
    FROM CTS_DataCenter.CustDCSAccount
	WHERE  CTSCustID  = ip_CTSCustID; 
    
    SELECT  SUM(DeviceDesktop)
		,   SUM(DeviceMobile)
        ,   SUM(DeviceOthers)
        ,   SUM(TotalLogin)
	INTO 	lv_Count_Device_Desktop
		,	lv_Count_Device_Mobile
        ,	lv_Count_Device_Others
        ,	lv_Count_Login
    FROM DCS_DataCenter.SumAccountLogin
    WHERE AccountID  = lv_AccountID
		AND TransDate BETWEEN ip_FromDate AND ip_ToDate; 
	
    SELECT  COUNT(1)
	INTO 	lv_Count_IP
    FROM DCS_DataCenter.AccountIP
    WHERE AccountID  = lv_AccountID
		AND LastTransDate BETWEEN ip_FromDate AND ip_ToDate; 
	
    SELECT  COUNT(1)
	INTO 	lv_Count_Device
    FROM DCS_DataCenter.AccountDevice
    WHERE AccountID  = lv_AccountID
		AND LastTransDate BETWEEN ip_FromDate AND ip_ToDate; 
    
    SELECT 	lv_Count_Device_Desktop 						AS DesktopUsage
		,	ROUND(lv_Count_Login/lv_Count_Device_Desktop,2)	AS DesktopUsagePercent
		,	lv_Count_Device_Mobile 							AS MobileUsage
        ,	ROUND(lv_Count_Login/lv_Count_Device_Desktop,2)	AS MobileUsagePercent
        ,	lv_Count_Device_Others 							AS OthersUsage
        ,	ROUND(lv_Count_Login/lv_Count_Device_Desktop,2)	AS OthersUsagePercent
        ,	lv_Count_Login 									AS Logins
        ,	lv_Count_IP 									AS IPs
        ,	lv_Count_Device 								AS Devices;
END$$

DELIMITER ;