/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_Notification_InsertProbationNotification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Notification_InsertProbationNotification`(IN ip_TotalScanned smallint,IN ip_TotalFailed smallint,IN ip_TotalGeneralFailed smallint)
    SQL SECURITY INVOKER
sp: BEGIN

   /*
		Created:	20200922@Harvey.Nguyen
		Task :		Insert notification for probation customer
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- [20201116-20201118@Irena.Vo][145028]: Enhance logic & remove NotificationType
		
        Param's Explanation:
			
		Sample:
			- call CTS_DataCenter.CTS_DC_Notification_InsertProbationNotification();
	*/    
    DECLARE lv_LimitedDay DATE DEFAULT DATE(DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY));
    
	-- Delete old data in ProbationAccountNotification
	DELETE FROM CTS_DataCenter.ProbationAccountNotification
	WHERE CreatedDate < lv_LimitedDay;
    
    -- Insert new message in ProbationAccountNotification
	INSERT IGNORE INTO CTS_DataCenter.ProbationAccountNotification(NotificationType, TotalScanned, TotalFailed,TotalGeneralFailed,CreatedDate,CreatedTime)
    VALUES (1, ip_TotalScanned,ip_TotalFailed,ip_TotalGeneralFailed,CURRENT_DATE(), CURRENT_TIME()); 
	
END$$

DELIMITER ;