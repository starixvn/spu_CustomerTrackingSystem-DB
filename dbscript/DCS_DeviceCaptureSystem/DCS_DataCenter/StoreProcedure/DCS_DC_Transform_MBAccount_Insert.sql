/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBAccount_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBAccount_Insert`(
	IN ip_AccountJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Insert MBAccount
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #214026]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBAccount_Insert('[{"SubscriberID":2,"LoginName":"qatest002","TransTime":"2024-11-21 05:06:07"}]');
            SELECT * FROM DCS_DataCenter.MBAccount ORDER BY ID DESC;
    */
    DECLARE lv_CurrentDatetime DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountInsert;
	CREATE TEMPORARY TABLE Temp_AccountInsert(
			SubscriberID			 	INT NOT NULL
		,	LoginName		 			VARCHAR(100) NOT NULL
		,	TransTime					DATETIME(4)
        
		,	IsNewRecord					TINYINT	DEFAULT 1
        
        ,	PRIMARY KEY (SubscriberID, LoginName)
    );
    
    INSERT IGNORE INTO Temp_AccountInsert(SubscriberID, LoginName, TransTime)
    SELECT	js.SubscriberID
		,	js.LoginName
		,	js.TransTime
	FROM JSON_TABLE(
			ip_AccountJson,
			 "$[*]" COLUMNS(
						SubscriberID		int			 	PATH "$.SubscriberID"
					,	LoginName			VARCHAR(100) 	PATH "$.LoginName"
					,	TransTime			DATETIME(4) 	PATH "$.TransTime"
				)
		   ) AS js
	WHERE js.SubscriberID IS NOT NULL
		AND js.LoginName IS NOT NULL;
	 
    UPDATE Temp_AccountInsert AS tmp
		INNER JOIN DCS_DataCenter.MBAccount AS acc ON acc.SubscriberID = tmp.SubscriberID AND acc.LoginName = tmp.LoginName
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.MBAccount(SubscriberID, LoginName, LastLoginTime, InsertedTime)
	SELECT	SubscriberID
		,	LoginName
		,	TransTime
		,	lv_CurrentDatetime
	FROM Temp_AccountInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;