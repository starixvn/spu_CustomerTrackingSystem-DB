/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Association_GetAssociationByDateRangeSubscriber`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Association_GetAssociationByDateRangeSubscriber`(
		IN	ip_SubscriberID	INT	    
    ,	IN	ip_FromDate		DATETIME
    ,	IN	ip_Limit		INT
    )
    SQL SECURITY INVOKER
proc_label: BEGIN
	/*
		Created:	20240611@Terry.Nguyen
		Task:		Get association by Range Date and Subscriber [Redmine ID: 206262]
		DB:			DCS_DataCenter
		Original:

		Revisions:
		- 20240611@Terry.Nguyen: 		Initial [Redmine ID: #206262]	           
		
        Param's Explanation (filtered by):

		Example:
			CALL DCS_DC_Association_GetAssociationByDateRangeSubscriber(@ip_SubscriberID:=2,@ip_FromDate:='2024-06-12 00:17:31.0000',@ip_Limit:=100); 			
            
	*/ 	   
     
    SELECT 		tmp.AssociationID	AS AssociationID
			,	tmp.DeviceID		AS DeviceID			
			,	ip_SubscriberID		AS SubscriberID						
			,	tmp.LoginName		AS LoginName
			,	tmp.FirstDeviceCode	AS FirstDeviceCode
			,	tmp.CreatedTime		AS CreatedTime
			,	tmp.AccountID		AS AccountID
            
		FROM	(
				SELECT 	ass.AssociationID
					,	ass.DeviceID
                    ,	dev.FirstDeviceCode
                    ,	ass.AccountID
                    ,	acc.LoginName
                    ,	ass.CreatedTime
				FROM	DCS_DataCenter.Association ass 				
					INNER JOIN DCS_DataCenter.Device AS dev ON ass.DeviceID = dev.DeviceID
					INNER JOIN DCS_DataCenter.Account AS acc ON ass.AccountID = acc.AccountID
				WHERE ass.CreatedTime >= ip_FromDate
					AND ass.SubscriberID = ip_SubscriberID
				) AS tmp
			ORDER BY ass.CreatedTime DESC
            LIMIT ip_Limit;    
    
END$$

DELIMITER ;
