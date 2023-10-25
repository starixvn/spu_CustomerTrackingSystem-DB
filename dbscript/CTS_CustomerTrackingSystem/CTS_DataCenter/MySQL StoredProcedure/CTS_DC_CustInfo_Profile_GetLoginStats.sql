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
			- 20231025@Jonas.Huynh: Get Invalid Browser Info and Bot Transaction [Redmine ID: #195095]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Profile_GetLoginStats(200);
	*/
	DECLARE lv_Count_Device_Desktop 		INT;
    DECLARE lv_Count_Device_Mobile 			INT;
    DECLARE lv_Count_Login					INT;
    DECLARE lv_Count_IP						INT;
    DECLARE lv_Count_Device					INT;
    DECLARE lv_Count_Bot_Trans				INT;
    DECLARE lv_Count_InvalidBrowser_Trans	INT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountID;
	CREATE TEMPORARY TABLE Temp_AccountID(
			AccountID	BIGINT UNSIGNED PRIMARY KEY
	);	
    
    INSERT IGNORE INTO Temp_AccountID(AccountID)
    SELECT AccountID 
    FROM CTS_DataCenter.CustDCSAccount
	WHERE  CTSCustID  = ip_CTSCustID; 
    
    IF (SELECT 1 FROM Temp_AccountID)
    THEN
		SELECT  SUM(sm.DeviceDesktop)
			,   SUM(sm.DeviceMobile)
			,   SUM(sm.TotalLogin)
		INTO 	lv_Count_Device_Desktop
			,	lv_Count_Device_Mobile
			,	lv_Count_Login
		FROM DCS_DataCenter.SumAccountLogin AS sm
		WHERE sm.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND sm.TransDate BETWEEN ip_FromDate AND ip_ToDate; 
		
		SELECT  COUNT(1)
		INTO 	lv_Count_IP
		FROM DCS_DataCenter.AccountIP AS ip
		WHERE ip.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND ip.LastTransDate BETWEEN ip_FromDate AND ip_ToDate; 
		
		SELECT  COUNT(1)
		INTO 	lv_Count_Device
		FROM DCS_DataCenter.AccountDevice AS dv
		WHERE dv.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND dv.LastTransDate BETWEEN ip_FromDate AND ip_ToDate; 
		
		SELECT  SUM(CASE WHEN st.GroupID = 2 THEN lg.TotalTrans ELSE 0 END) AS Invalid
			,	SUM(CASE WHEN st.GroupID = 3 THEN lg.TotalTrans ELSE 0 END) AS Bot
		INTO 	lv_Count_InvalidBrowser_Trans
			,	lv_Count_Bot_Trans
		FROM DCS_DataTrace.LoginTransactionSummary AS lg
			INNER JOIN DCS_DataCenter.StaticList AS st ON st.ItemID = lg.Flagged AND st.ListID = 1
		WHERE lg.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND lg.TransDate BETWEEN ip_FromDate AND ip_ToDate; 
			
		SELECT 	lv_Count_Bot_Trans 											AS BotTrans
			,	ROUND((lv_Count_Bot_Trans/lv_Count_Login)*100,2)			AS BotTransPercentage
			,	lv_Count_InvalidBrowser_Trans 								AS InvalidBrowser
			,	ROUND((lv_Count_InvalidBrowser_Trans/lv_Count_Login)*100,2)	AS InvalidBrowserPercentage
			,	lv_Count_Device_Desktop 									AS DesktopUsage
			,	lv_Count_Device_Mobile 										AS MobileUsage
			,	lv_Count_IP 												AS IP
			,	lv_Count_Device 											AS Device
			,	lv_Count_Login 												AS Login;
	END IF;
END$$

DELIMITER ;