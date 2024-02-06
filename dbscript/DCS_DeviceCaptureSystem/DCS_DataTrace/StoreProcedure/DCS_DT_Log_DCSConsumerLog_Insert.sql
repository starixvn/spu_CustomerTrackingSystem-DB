/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Log_DCSConsumerLog_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Log_DCSConsumerLog_Insert`(
    IN ip_ConsumerLogJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20240206@Jonathan.Doan
	Task : Insert data into DCSConsumer_Log
	DB: DCS_DataTrace
	Original:

	Revisions:
		-20240206@Jonathan.Doan: Created [Redmine ID: 200900]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Log_DCSConsumerLog_Insert('[{"SessionKey":"123","LoginName":"Test01","SubscriberName":"Alpha","TransTime":"2024-02-06 13:54:12.123","UserAgent":"Mozilla Chrome 120","URL":"http://localhost:5000"},{"SessionKey":"124","LoginName":"Test02","SubscriberName":"Alpha1","TransTime":"2024-02-06 13:54:12.123","UserAgent":"Mozilla Chrome 121","URL":"http://localhost:5001"}]');
	*/
    
	DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    INSERT IGNORE INTO DCS_DataTrace.DCSConsumer_Log(SessionKey, LoginName, SubscriberName, TransTime, UserAgent, URL, CreatedDate, InsertedTime)
	SELECT	tmp.SessionKey
		,	tmp.LoginName
		,   tmp.SubscriberName
        ,	tmp.TransTime
		,	tmp.UserAgent
        ,	tmp.URL
        ,	DATE(lv_CurrentDatetime) AS CreatedDate
        ,	lv_CurrentDatetime AS InsertedTime
	FROM JSON_TABLE(
			ip_ConsumerLogJson,
			 "$[*]" COLUMNS(
					SessionKey			VARCHAR(100)		PATH "$.SessionKey"
				,	LoginName			VARCHAR(100)		PATH "$.LoginName"
                ,   SubscriberName		VARCHAR(50)			PATH "$.SubscriberName"
				,	TransTime			TIMESTAMP(4)		PATH "$.TransTime"
                ,	UserAgent			VARCHAR(1000)		PATH "$.UserAgent"
				,	URL					VARCHAR(500) 		PATH "$.URL"
			)
		) AS tmp;
END$$
DELIMITER ;