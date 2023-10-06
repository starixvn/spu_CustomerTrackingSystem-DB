/*<info serverAlias="CTSMain-DCS_DataWatch" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DW_Summary_BetTicket_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DW_Summary_BetTicket_Insert`(
    IN ip_InputJson LONGTEXT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231003@Jonathan.Doan
	Task : Insert data into BetTicketLite
	DB: DCS_DataWatch
	Original:

	Revisions:
		- 20231003@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataWatch.DCS_DW_Summary_BetTicket_Insert('[{"TransDate":"2023-10-04","CustID":1,"BetCount":100,"FirstBetTicketTime":"2023-10-04 05:04:00","LastBetTicketTime":"2023-10-04 10:05:00"}]');
	*/
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_InputTrans(
			ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	TransDate			DATETIME NOT NULL
		, 	CustID				INT UNSIGNED DEFAULT NULL
		, 	BetCount			INT UNSIGNED DEFAULT 0
		, 	FirstBetTicketTime	DATETIME DEFAULT NULL
		, 	LastBetTicketTime	DATETIME DEFAULT NULL
		, 	IsUpdate			BOOL DEFAULT 0
		,	PRIMARY KEY (`ID`)
	);
	
    INSERT INTO Temp_InputTrans(TransDate, CustID, BetCount, FirstBetTicketTime, LastBetTicketTime)
	SELECT	tmp.TransDate
		,	tmp.CustID
		,	tmp.BetCount
		,	tmp.FirstBetTicketTime
		,	tmp.LastBetTicketTime
	FROM JSON_TABLE(
			ip_InputJson,
			 "$[*]" COLUMNS(
					TransDate				DATETIME			PATH "$.TransDate"
				,	CustID					INT UNSIGNED		PATH "$.CustID"
				,	BetCount				INT UNSIGNED		PATH "$.BetCount"
				,	FirstBetTicketTime		DATETIME			PATH "$.FirstBetTicketTime"
				,	LastBetTicketTime		DATETIME			PATH "$.LastBetTicketTime"
			)
		) AS tmp;

	UPDATE DCS_DataWatch.BetTicket AS bt
		INNER JOIN Temp_InputTrans AS tmp ON tmp.TransDate = bt.TransDate AND tmp.CustID = bt.CustID
	SET bt.BetCount = tmp.BetCount,
		bt.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;

	INSERT INTO DCS_DataWatch.BetTicket(TransDate, CustID, BetCount, FirstBetTicketTime, LastBetTicketTime, CreatedTime, ModifiedTime)
	SELECT 	TransDate
		,	CustID
        ,	BetCount
        ,	FirstBetTicketTime
        ,	LastBetTicketTime
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
    FROM Temp_InputTrans
    WHERE IsUpdate = 0;
END$$
DELIMITER ;
