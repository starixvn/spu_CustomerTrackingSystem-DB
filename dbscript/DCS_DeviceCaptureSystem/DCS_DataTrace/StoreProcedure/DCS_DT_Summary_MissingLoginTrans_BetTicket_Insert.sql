/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_MissingLoginTrans_BetTicket_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_MissingLoginTrans_BetTicket_Insert`()
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231003@Jonathan.Doan
	Task : Insert data into MissingLoginTransaction, MissingBetTicket
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231003@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Summary_MissingLoginTrans_BetTicket_Insert(10);
	*/
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_MaxTransDate DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransDate = (SELECT DATE(VValue) FROM DCS_DataTrace.SystemSetting WHERE ID = 2);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_BetTicket;
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_MissingLoginTransaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_MissingBetTicket;
	DROP TEMPORARY TABLE IF EXISTS Temp_CustHistory;
    
	CREATE TEMPORARY TABLE Temp_BetTicket(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		, 	FirstBetTicketTime		DATETIME DEFAULT NULL
		, 	LastBetTicketTime		DATETIME DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	UNIQUE KEY `UX_Temp_BetTicket_CustID` (`CustID`)
	);
    
	CREATE TEMPORARY TABLE Temp_LoginTransaction(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	RoleID					TINYINT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		, 	FirstLoginTransTime		DATETIME DEFAULT NULL
		, 	LastLoginTransTime		DATETIME DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_LoginTransaction_CustID` (`CustID`)
		,	UNIQUE KEY `UX_Temp_LoginTransaction_GROUP` (`SubscriberID`, `CustID`, `RoleID`)
	);
    
	CREATE TEMPORARY TABLE Temp_MissingLoginTransaction(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
	);
    
	CREATE TEMPORARY TABLE Temp_MissingBetTicket(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
	);
    
	CREATE TEMPORARY TABLE Temp_CustHistory(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		, 	FirstLoginTransTime		DATETIME DEFAULT NULL
		, 	LastLoginTransTime		DATETIME DEFAULT NULL
		, 	FirstBetTicketTime		DATETIME DEFAULT NULL
		, 	LastBetTicketTime		DATETIME DEFAULT NULL
		, 	IsUpdate				BOOL DEFAULT 0
		,	PRIMARY KEY (`ID`)
		,	UNIQUE KEY `UX_Temp_CustHistory_SubscriberID_CustID` (`SubscriberID`, `CustID`)
	);
    
    INSERT INTO Temp_BetTicket(CustID, SubscriberID, FirstBetTicketTime, LastBetTicketTime)
    SELECT 	bt.CustID
        ,	cts.SubscriberID
        ,	bt.FirstBetTicketTime
        ,	bt.LastBetTicketTime
    FROM DCS_DataTrace.BetTicket AS bt
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CustID = bt.CustID AND cts.RoleID = 1
    WHERE bt.TransDate = lv_MaxTransDate;
    
    INSERT INTO Temp_LoginTransaction(CustID, RoleID, SubscriberID, FirstLoginTransTime, LastLoginTransTime)
    SELECT 	cts.CustID
        ,	cts.RoleID
        ,	trans.SubscriberID
        ,	MIN(trans.FirstLoginTransTime) AS FirstLoginTransTime
        ,	MAX(trans.LastLoginTransTime) AS LastLoginTransTime
    FROM DCS_DataTrace.LoginTransaction AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
    WHERE trans.TransDate = lv_MaxTransDate
    GROUP BY cts.CustID, cts.RoleID, trans.SubscriberID;
    
    /* == MissingLoginTransaction == */
    INSERT INTO Temp_MissingLoginTransaction(CustID, SubscriberID)
    SELECT 	tmp_bt.CustID
        ,	tmp_bt.SubscriberID
    FROM Temp_BetTicket AS tmp_bt
		LEFT JOIN Temp_LoginTransaction AS tmp_trans ON tmp_trans.CustID = tmp_bt.CustID
    WHERE tmp_trans.ID IS NULL;
    
    DELETE FROM DCS_DataTrace.MissingLoginTransaction WHERE TransDate = lv_MaxTransDate;
    
    INSERT INTO DCS_DataTrace.MissingLoginTransaction(TransDate, CustID, SubscriberID, CreatedTime)
    SELECT 	lv_MaxTransDate AS TransDate
		,	CustID
		,	SubscriberID
        ,	lv_CurrentDatetime AS CreatedTime
    FROM Temp_MissingLoginTransaction;
    
    
    /* == MissingLoginTransaction == */
    INSERT INTO Temp_MissingBetTicket(CustID, SubscriberID)
    SELECT 	tmp_trans.CustID
        ,	tmp_trans.SubscriberID
    FROM Temp_LoginTransaction AS tmp_trans
		LEFT JOIN Temp_BetTicket AS tmp_bt ON tmp_bt.CustID = tmp_trans.CustID
    WHERE tmp_bt.ID IS NULL
		AND tmp_trans.RoleID = 1;
    
    DELETE FROM DCS_DataTrace.MissingBetTicket WHERE TransDate = lv_MaxTransDate;
    
    INSERT INTO DCS_DataTrace.MissingBetTicket(TransDate, CustID, SubscriberID, CreatedTime)
    SELECT 	lv_MaxTransDate AS TransDate
		,	CustID
		,	SubscriberID
        ,	lv_CurrentDatetime AS CreatedTime
    FROM Temp_MissingBetTicket;
    
    /* == CustHistory == */
    INSERT INTO Temp_CustHistory(CustID, SubscriberID, FirstLoginTransTime, LastLoginTransTime, FirstBetTicketTime, LastBetTicketTime)
    SELECT 	tmp_trans.CustID
		,	tmp_trans.SubscriberID
		,	tmp_trans.FirstLoginTransTime
		,	tmp_trans.LastLoginTransTime
		,	tmp_bt.FirstBetTicketTime
		,	tmp_bt.LastBetTicketTime
	FROM Temp_LoginTransaction AS tmp_trans
		LEFT JOIN Temp_BetTicket AS tmp_bt ON tmp_bt.CustID = tmp_trans.CustID;
        
    INSERT INTO Temp_CustHistory(CustID, SubscriberID, FirstLoginTransTime, LastLoginTransTime, FirstBetTicketTime, LastBetTicketTime)
    SELECT 	tmp_bt.CustID
		,	tmp_bt.SubscriberID
		,	NULL AS FirstLoginTransTime
		,	NULL AS LastLoginTransTime
		,	tmp_bt.FirstBetTicketTime
		,	tmp_bt.LastBetTicketTime
	FROM Temp_LoginTransaction AS tmp_trans
		RIGHT JOIN Temp_BetTicket AS tmp_bt  ON tmp_bt.CustID = tmp_trans.CustID
	WHERE tmp_trans.ID IS NULL;
    
    UPDATE DCS_DataTrace.CustHistory AS ch
		INNER JOIN Temp_CustHistory AS tmp ON tmp.CustID = ch.CustID
	SET 	ch.FirstLoginTransTime = tmp.FirstLoginTransTime
		,	ch.LastLoginTransTime = tmp.LastLoginTransTime
		,	ch.FirstBetTicketTime = tmp.FirstBetTicketTime
		,	ch.LastBetTicketTime = tmp.LastBetTicketTime
		,	ch.ModifiedTime = lv_CurrentDatetime
		,	tmp.IsUpdate = 1
	WHERE ch.TransDate = lv_MaxTransDate;
    
    INSERT INTO DCS_DataTrace.CustHistory(TransDate, CustID, SubscriberID, FirstLoginTransTime, LastLoginTransTime, FirstBetTicketTime, LastBetTicketTime, CreatedTime, ModifiedTime)
    SELECT 	lv_MaxTransDate AS TransDate
		,	CustID
		,	SubscriberID
		,	FirstLoginTransTime
        ,	LastLoginTransTime
        ,	FirstBetTicketTime
        ,	LastBetTicketTime
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
    FROM Temp_CustHistory
    WHERE IsUpdate = 0;
    
    SET lv_MaxTransDate = DATE_ADD(lv_MaxTransDate, INTERVAL 1 DAY);
END$$
DELIMITER ;
