/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step30_Account_Delete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step30_Account_Delete`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		Delete Account 
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/ 
	DECLARE lv_FromAccountID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToAccountID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_StartTime DATETIME(3) DEFAULT NOW();
    
	SELECT 	MIN(tmp.AccountID), MAX(tmp.AccountID)
	INTO 	lv_FromAccountID, lv_ToAccountID
	FROM	(SELECT delAcc.AccountID FROM CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc WHERE delAcc.AccountID > lv_ToAccountID LIMIT ip_Size) AS tmp;
    
	INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(30, 30,'CTS_AD_DelUnuAccount_Step30_Account_Delete',lv_StartTime,NOW(), lv_FromAccountID);   
    
	#====Step01. Remove Account From CS152454_DelUnuAccount_Account: IsCTSTransformed = 1 OR LastLoginTime >= '20210101' OUTPUT UmRemoveAccountID
    WHILE(lv_FromAccountID IS NOT NULL)
    DO		
	
            DELETE 		acc
            FROM		DCS_DataCenter.Account acc
            INNER JOIN	CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc ON delAcc.AccountID = acc.AccountID
            WHERE		delAcc.AccountID BETWEEN  lv_FromAccountID AND lv_ToAccountID;
			
			UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
			SET 	Notes = lv_FromAccountID
					, EndTime = NOW()
			WHERE ID = 30;
            
            SELECT 	MIN(tmp.AccountID), MAX(tmp.AccountID)
			INTO 	lv_FromAccountID, lv_ToAccountID
			FROM	(SELECT delAcc.AccountID FROM CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc WHERE delAcc.AccountID > lv_ToAccountID LIMIT ip_Size) AS tmp;                  
            
            DO SLEEP(ip_DelaySec);
    END WHILE;


END