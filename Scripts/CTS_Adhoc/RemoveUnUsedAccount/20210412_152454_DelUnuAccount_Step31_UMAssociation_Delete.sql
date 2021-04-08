/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/


DROP PROCEDURE IF EXISTS `CTS_AD_DelUnuAccount_Step31_Association_Delete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_AD_DelUnuAccount_Step31_Association_Delete`(
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
	DECLARE lv_FromAssociationID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_ToAssociationID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_StartTime DATETIME(3) DEFAULT NOW();
    
	SELECT 	MIN(tmp.AssociationID), MAX(tmp.AssociationID)
	INTO 	lv_FromAssociationID, lv_ToAssociationID
	FROM	(SELECT delAss.AssociationID FROM CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss WHERE delAss.AssociationID > lv_ToAssociationID LIMIT ip_Size) AS tmp;
    
    INSERT INTO CTS_Adhoc.CS152454_DelUnuAccount_zzTrace(ID, Steps,SPName, StartTime,EndTime,Notes)
    VALUES(31, 31,'CTS_AD_DelUnuAccount_Step31_Association_Delete',lv_StartTime,NOW(),lv_FromAssociationID); 
    
	#====Step01. Remove Account From CS152454_DelUnuAccount_Association: IsCTSTransformed = 1 OR LastLoginTime >= '20210101' OUTPUT UmRemoveAssociationID
    WHILE(lv_FromAssociationID IS NOT NULL)
    DO		
	
            DELETE 		ass
            FROM		DCS_DataCenter.Association ass
            INNER JOIN	CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss ON delAss.AssociationID = ass.AssociationID
            WHERE		delAss.AssociationID BETWEEN  lv_FromAssociationID AND lv_ToAssociationID;
            
            UPDATE CTS_Adhoc.CS152454_DelUnuAccount_zzTrace
			SET 	Notes = lv_ToAssociationID
					, EndTime = NOW()
			WHERE ID = 31;
                        
            SELECT 	MIN(tmp.AssociationID), MAX(tmp.AssociationID)
			INTO 	lv_FromAssociationID, lv_ToAssociationID
			FROM	(SELECT delAss.AssociationID FROM CTS_Adhoc.CS152454_DelUnuAccount_Association AS delAss WHERE delAss.AssociationID > lv_ToAssociationID LIMIT ip_Size) AS tmp;       
            
    END WHILE;
    
END