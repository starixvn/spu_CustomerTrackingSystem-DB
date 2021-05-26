/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/
USE CTS_Adhoc;
DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step12_Association_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step12_Association_Get`(
		IN ip_Size INT
        , IN ip_DelaySec TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		GET Association of Deleted Account
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/ 
	
  
    DECLARE	lv_FromAccountID	BIGINT UNSIGNED; #FromAccountID
    DECLARE	lv_ToAccountID		BIGINT UNSIGNED; #ToAccountID
    DECLARE	lv_MaxAccountID		BIGINT UNSIGNED;
    DECLARE	lv_StartTime		DATETIME(3);	
		
    
    SET	lv_StartTime = NOW();

    SET lv_FromAccountID = 1;
    SET lv_ToAccountID = 1;
    SET lv_MaxAccountID = (SELECT MAX(acc.AccountID) FROM CTS_Adhoc.CS152454_DelUnuAccount_Account AS acc );
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(12, 12,'CTS_AD_DelUnuAccount_Step12_Association_Get',lv_StartTime,NOW(), 0);   
    
    WHILE (lv_ToAccountID != lv_MaxAccountID)
    DO			
		 SET	lv_ToAccountID = (	SELECT MAX(tmp.AccountID) 
									FROM	(	SELECT 	acc.AccountID 
												FROM	CTS_Adhoc.CS152454_DelUnuAccount_Account AS acc 
												WHERE 	acc.AccountID >  lv_FromAccountID
                                                LIMIT ip_Size 
											) tmp);       
        
        INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_Association( AccountID, DeviceID, AssociationID, SubscriberID, CreatedTime, CreatedDate, InsertTime, IsCTSTransformed)
        SELECT	acc.AccountID
				, ass.DeviceID
                , ass.AssociationID
                , ass.SubscriberID
                , ass.CreatedTime
                , ass.CreatedDate
                , ass.InsertTime
                , ass.IsCTSTransformed
        FROM	CTS_Adhoc.CS152454_DelUnuAccount_Account AS acc
			INNER JOIN DCS_DataCenter.Association AS ass ON acc.AccountID = ass.AccountID
        WHERE	acc.AccountID BETWEEN lv_FromAccountID AND lv_ToAccountID;
            
		#========================================================
        
        SET lv_FromAccountID = lv_ToAccountID + 1;
        
		UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
		SET 	Notes = lv_ToAccountID
				, EndTime = NOW()
		WHERE ID = 12;		
        
        DO SLEEP(ip_DelaySec);     
    END WHILE;   

END$$

DELIMITER ;


