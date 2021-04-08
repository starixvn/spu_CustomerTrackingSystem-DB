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
	
  
    DECLARE	lv_PreAccountID		BIGINT UNSIGNED; # The Last AccountID
    DECLARE	lv_StartTime		DATETIME(3);	
    
    SET	lv_StartTime = NOW();
    
    SET	@lv_152454ToAccountID = 0;
    SET lv_PreAccountID = 1;
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(12, 12,'CTS_AD_DelUnuAccount_Step12_Association_Get',lv_StartTime,NOW(), @lv_152454ToAccountID);   
    
    WHILE (@lv_152454ToAccountID != lv_PreAccountID )
    DO			
		SET lv_PreAccountID = @lv_152454ToAccountID;
        
        INSERT IGNORE INTO CTS_Adhoc.CS152454_DelUnuAccount_Association( AccountID, DeviceID, AssociationID, SubscriberID, CreatedTime, CreatedDate, InsertTime, IsCTSTransformed)
        SELECT	@lv_152454ToAccountID := acc.AccountID
				, ass.DeviceID
                , ass.AssociationID
                , ass.SubscriberID
                , ass.CreatedTime
                , ass.CreatedDate
                , ass.InsertTime
                , ass.IsCTSTransformed
        FROM	CTS_Adhoc.CS152454_DelUnuAccount_Account AS acc
			INNER JOIN DCS_DataCenter.Association AS ass ON acc.AccountID = ass.AccountID
        WHERE	acc.AccountID > lv_PreAccountID
        LIMIT	ip_Size;   
            
		#========================================================
		UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
		SET 	Notes = lv_PreAccountID
				, EndTime = NOW()
		WHERE ID = 12;		
        
        DO SLEEP(ip_DelaySec);     
    END WHILE;   

END$$

DELIMITER ;


