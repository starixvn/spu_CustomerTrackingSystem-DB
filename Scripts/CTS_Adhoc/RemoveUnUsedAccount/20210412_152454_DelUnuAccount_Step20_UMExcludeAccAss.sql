/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step20_UMExcludeAccAss`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step20_UMExcludeAccAss`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		Remove the Account and Association In UM Time If ((acc.ISCTSTransformed = 1	OR acc.LastLoginTime >= '2021-01-01')
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/   
    DECLARE lv_FromAccountID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxAccountID	BIGINT UNSIGNED;
    DECLARE lv_StartTime DATETIME(3) DEFAULT NOW();
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveAccountID;
    CREATE TEMPORARY TABLE Temp_RemoveAccountID
    (
		AccountID BIGINT UNSIGNED PRIMARY KEY
    ); 

	INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(20, 20,'CTS_AD_DelUnuAccount_Step20_UMExcludeAccAss',lv_StartTime,NOW(), lv_FromAccountID);   
    
    WHILE(lv_FromAccountID IS NOT NULL)
    DO		
			INSERT INTO Temp_RemoveAccountID(AccountID)
			SELECT 		delAcc.AccountID
			FROM		CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc
			INNER JOIN	DCS_DataCenter.Account AS acc ON delAcc.AccountID = acc.AccountID
			WHERE		(acc.ISCTSTransformed = 1
						OR acc.LastLoginTime >= '2021-01-01')
						AND delAcc.AccountID > lv_FromAccountID
			LIMIT ip_Size;   
            
			SET lv_FromAccountID = (SELECT MAX(AccountID) FROM Temp_RemoveAccountID);

			DELETE 		delAcc
			FROM 		CTS_Adhoc.CS152454_DelUnuAccount_Account AS delAcc
			INNER JOIN 	Temp_RemoveAccountID AS tmpAcc ON delAcc.AccountID = tmpAcc.AccountID;
			
			DELETE 		delAss
			FROM 		CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss
			INNER JOIN 	Temp_RemoveAccountID AS tmpAcc ON delAss.AccountID = tmpAcc.AccountID;
            
            #=============================================
            UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
			SET 	Notes = lv_FromAccountID
					, EndTime = NOW()
			WHERE ID = 20;
            
            TRUNCATE TABLE Temp_RemoveAccountID;
            
			DO SLEEP(ip_DelaySec);  
    END WHILE;

END