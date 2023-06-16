/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Notify_MonitorTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Notify_MonitorTransaction_Insert`(
		IN ip_RptDate 			DATE
	,	IN ip_BactchSize 		INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20230615@Jonathan.Doan
	    Task : Store data Monitor Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:		    
			-	20230615@Jonathan.Doan: Created [Redmine ID: 189732]
            
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_Notify_MonitorTransaction_Insert('2023-04-01', 3);
    */    
    DECLARE lv_Title VARCHAR(1000);
    DECLARE lv_Message LONGTEXT;
    DECLARE lv_CountResult INT UNSIGNED;
    DECLARE lv_ListUserName VARCHAR(2000);
    DECLARE lv_CurDate DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_Title = CONCAT('FPS-Cust-MissedTrans ', DATE_FORMAT(ip_RptDate, '%m/%d/%Y'));
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MonitorTransaction;
    CREATE TEMPORARY TABLE Temp_MonitorTransaction(
			CustID		 	INT UNSIGNED PRIMARY KEY 
        ,	UserName		VARCHAR(50) NULL
    );
    
    INSERT INTO Temp_MonitorTransaction(CustID, UserName)
    SELECT	CustID
		,	UserName
	FROM DCS_DataCenter.MonitorTransaction
	WHERE LastScanDate = ip_RptDate;
    
    SELECT COUNT(CustID)
    INTO lv_CountResult
    FROM Temp_MonitorTransaction;
    
    WITH cte_GroupUserName AS (
		SELECT UserName
		FROM Temp_MonitorTransaction
        ORDER BY CustID
		LIMIT ip_BactchSize
    )
	SELECT REPLACE(GROUP_CONCAT(UserName), ',', ', ')
    INTO lv_ListUserName
    FROM cte_GroupUserName;
    
    SET lv_Message = 'Please kindly check the following Usersname without Transaction';
    SET lv_Message = CONCAT(lv_Message,'\n - Total Usernames: ', lv_CountResult);
    SET lv_Message = CONCAT(lv_Message,'\n - Top ',ip_BactchSize,' Usernames: ',lv_ListUserName, lv_CountResult);
    
    INSERT INTO DCS_DataCenter.NotifyMessage(Title, Message, CreatedDate, IsNotified)
    SELECT	lv_Title AS Title
		,	lv_Message AS Message
		,	lv_CurDate AS CreatedDate
		,	0 AS IsNotified;
    
    
END$$
DELIMITER ;
