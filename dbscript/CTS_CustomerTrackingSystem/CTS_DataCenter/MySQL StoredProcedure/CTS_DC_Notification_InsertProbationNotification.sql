USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Notification_InsertProbationNotification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsService`@`%` PROCEDURE `CTS_DC_Notification_InsertProbationNotification`(
		IN ip_NotificationType		TINYINT
	, 	IN ip_TotalScanned			SMALLINT
    , 	IN ip_TotalFailed			SMALLINT
    , 	IN ip_TotalGeneralFailed	SMALLINT
)
sp: BEGIN
	/*
		Created:	20200922@Harvey.Nguyen
		Task :		Insert notification for probation customer
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			-
		
        Param's Explanation:
			
		Sample:
			- call CTS_DataCenter.CTS_DC_Notification_InsertProbationNotification();
	*/    
    
	INSERT INTO CTS_DataCenter.ProbationAccountNotification(NotificationType, TotalScanned, TotalFailed,TotalGeneralFailed,CreatedDate,CreatedTime)
    VALUES (ip_NotificationType,ip_TotalScanned,ip_TotalFailed,ip_TotalGeneralFailed,current_date(), current_time());
	
END$$

DELIMITER ;

