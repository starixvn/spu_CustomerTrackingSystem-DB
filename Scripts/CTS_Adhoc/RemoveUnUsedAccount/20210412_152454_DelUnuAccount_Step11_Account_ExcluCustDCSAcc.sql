/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

USE CTS_Adhoc;
DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step11_Account_ExcluCustDCSAcc`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step11_Account_ExcluCustDCSAcc`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		GET Account Has IsCTSTransformed < 0 and LastLogtin < (90days)
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
        
        Steps:SELECT `CS152454_DelUnuAccount_Account_Excluded`.`AccountID`,
    `CS152454_DelUnuAccount_Account_Excluded`.`SubscriberID`,
    `CS152454_DelUnuAccount_Account_Excluded`.`InsertTime`,
    `CS152454_DelUnuAccount_Account_Excluded`.`cdaCTSCustID`
FROM `CTS_Adhoc`.`CS152454_DelUnuAccount_Account_Excluded`;

        1. Get Old Account I
	*/    
    
    DECLARE	lv_PreAccountID		BIGINT UNSIGNED; # The Last AccountID
    DECLARE lv_StartTime	DATETIME(3) DEFAULT NOW();
    
    SET	lv_StartTime = NOW();
    
    SET	@lv_152454ToAccountID = 0;
    SET lv_PreAccountID = 1;   

    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
	VALUES(11, 11,'CTS_AD_DelUnuAccount_Step11_Account_ExcluCustDCSAcc',lv_StartTime, NOW(), @lv_152454ToAccountID); 
    
    WHILE (@lv_152454ToAccountID != lv_PreAccountID )
    DO			
		SET lv_PreAccountID = @lv_152454ToAccountID;
        
        INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_Account_Excluded(AccountID, SubscriberID, InsertTime, cdaCTSCustID)
        SELECT	@lv_152454ToAccountID := acc.AccountID
            ,	acc.SubscriberID
            ,	acc.InsertTime
            ,	cda.CTSCustID
        FROM	CTS_Adhoc.CS152454_DelUnuAccount_Account AS acc
			INNER JOIN CTS_DataCenter.CustDCSAccount AS cda ON acc.AccountID = cda.AccountID
        WHERE	acc.AccountID > lv_PreAccountID
        LIMIT	ip_Size;
        
        DELETE	acc
        FROM	CTS_Adhoc.CS152454_DelUnuAccount_Account AS acc
			INNER JOIN CS152454_DelUnuAccount_Account_Excluded AS exc ON acc.AccountID = exc.AccountID
		WHERE	acc.AccountID > lv_PreAccountID; 	      
         
        UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
        SET 	Notes = @lv_152454ToAccountID
				, EndTime = NOW()
        WHERE ID = 11;
        
        DO SLEEP(ip_DelaySec);     
    END WHILE;   
    
END$$

DELIMITER ;


