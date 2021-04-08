/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/
USE CTS_Adhoc;
DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step10_Account_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step10_Account_Get`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		GET Account Has IsCTSTransformed < 0 and (CreatedDate and LastLogtin) < 2021-01-01
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
        
        Steps:
        1. Get Old Account I
	*/     
    
    DECLARE	lv_PreAccountID	BIGINT UNSIGNED; # The Last AccountID
    DECLARE	lv_ToAccountID		BIGINT UNSIGNED;
    DECLARE	lv_MaxAccountID		BIGINT UNSIGNED;
    DECLARE lv_StartTime	DATETIME(3) DEFAULT NOW();	
    
    SET	lv_StartTime = NOW();
    
    SET	@lv_152454ToAccountID = 0;
    SET lv_PreAccountID = 1;

    SELECT 	IFNULL(MAX(AccountID),0)
    INTO	@lv_152454ToAccountID
    FROM	CTS_Adhoc.CS152454_DelUnuAccount_Account;    

    SET lv_MaxAccountID = 27572620;#(SELECT AccountID FROM DCS_DataCenter.Account WHERE CreatedDate >= '2021-01-01' AND AccountID > 27500000  LIMIT 1);
       
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(10, 10,'CTS_AD_DelUnuAccount_Step10_Account_Get',lv_StartTime,NOW(), @lv_152454ToAccountID);   
    
    WHILE (@lv_152454ToAccountID != lv_PreAccountID )
    DO	
		
		SET lv_PreAccountID = @lv_152454ToAccountID;
        
        INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_Account(AccountID, LoginName, SubscriberID, SubscriberType, CreatedTime, LastLoginTime, CreatedDate, InsertTime, IsCTSTransformed)
        SELECT	@lv_152454ToAccountID := AccountID
			,	acc.LoginName
            ,	acc.SubscriberID
            ,	acc.SubscriberType
            ,	acc.CreatedTime
            ,	acc.LastLoginTime
            ,	acc.CreatedDate
            ,	acc.InsertTime
            ,	acc.IsCTSTransformed
        FROM	DCS_DataCenter.Account AS acc
        WHERE	acc.IsCTSTransformed < 0 
				AND acc.AccountID > lv_PreAccountID
                AND acc.AccountID < lv_MaxAccountID
                AND acc.LastLoginTime < '2021-01-01'
        LIMIT	ip_Size;
        
        UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
        SET 	Notes = @lv_152454ToAccountID
				, EndTime = NOW()
        WHERE ID = 10;
        
        DO SLEEP(ip_DelaySec);         
        
    END WHILE;    

END$$

DELIMITER ;


