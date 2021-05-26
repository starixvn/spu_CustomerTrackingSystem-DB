/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

USE CTS_Adhoc;
DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step31_Association_Delete_V1`;

DELIMITER $$
CREATE DEFINER=`casey.vn`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step31_Association_DeleteV1`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		Delete Association 
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/ 
	DECLARE lv_FromAccountID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToAccountID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_StartTime DATETIME(3) DEFAULT NOW();
    
	SELECT 	MIN(tmp.AccountID), MAX(tmp.AccountID)
	INTO 	lv_FromAccountID, lv_ToAccountID
	FROM	(SELECT DISTINCT delAss.AccountID FROM CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss WHERE delAss.AccountID > lv_ToAccountID ORDER BY delAss.AccountID   LIMIT ip_Size) AS tmp;
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(310, 310,'CTS_AD_DelUnuAccount_Step31_Association_Delete_v1',lv_StartTime,NOW(),lv_FromAccountID); 
    
	#====Step01. Remove Account From CS152454_DelUnuAccount_Association: IsCTSTransformed = 1 OR LastLoginTime >= '20210101' OUTPUT UmRemoveAssociationID
    WHILE(lv_FromAccountID IS NOT NULL)
    DO		
	
            DELETE 		ass
            FROM		DCS_DataCenter.Association ass
            INNER JOIN	CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss ON delAss.AccountID = ass.AccountID
            WHERE		delAss.AccountID BETWEEN  lv_FromAccountID AND lv_ToAccountID;
            
            UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
			SET 	Notes = lv_ToAccountID
					, EndTime = NOW()
			WHERE ID = 31;
                        
            SELECT 	MIN(tmp.AssociationID), MAX(tmp.AssociationID)
			INTO 	lv_FromAccountID, lv_ToAccountID
			FROM	(SELECT delAss.AssociationID FROM CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss 
						WHERE delAss.AccountID > lv_ToAccountID ORDER BY delAss.AccountID LIMIT ip_Size ) AS tmp;  
            
            DO SLEEP(ip_DelaySec);
    END WHILE;
    
END$$