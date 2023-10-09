/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_MissingBetTicket_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_MissingBetTicket_Insert`(
        IN ip_FromID   BIGINT UNSIGNED
    ,   IN ip_ToID     BIGINT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231009@Jonathan.Doan
	Task : Insert MissingBetTicket by range ID
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231009@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Summary_MissingBetTicket_Insert(1, 2);
	*/
    DECLARE CONST_SUMMARY_MAXBETTICKETDATE INT DEFAULT 2;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_MaxTransDate DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransDate = (SELECT DATE(VValue) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_SUMMARY_MAXBETTICKETDATE);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_BetTicket;
	DROP TEMPORARY TABLE IF EXISTS Temp_MissingLoginTransaction;
    
	CREATE TEMPORARY TABLE Temp_LoginTransaction(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_LoginTransaction_CustID` (`CustID`)
		,	UNIQUE KEY `UX_Temp_LoginTransaction_GROUP` (`SubscriberID`, `CustID`)
	);
    
	CREATE TEMPORARY TABLE Temp_BetTicket(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	UNIQUE KEY `UX_Temp_BetTicket_CustID` (`CustID`)
	);
    
	CREATE TEMPORARY TABLE Temp_MissingLoginTransaction(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
	);
    
    INSERT INTO Temp_LoginTransaction(CustID, SubscriberID)
    SELECT 	DISTINCT 
			cts.CustID
        ,	trans.SubscriberID
    FROM DCS_DataTrace.LoginTransaction AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
    WHERE trans.ID BETWEEN ip_FromID AND ip_ToID
		AND trans.TransDate = lv_MaxTransDate
        AND cts.RoleID = 1;
    
    INSERT INTO Temp_BetTicket(CustID, SubscriberID)
    SELECT 	bt.CustID
        ,	cts.SubscriberID
    FROM DCS_DataTrace.BetTicket AS bt
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CustID = bt.CustID
    WHERE bt.TransDate = lv_MaxTransDate;
    
    /* == MissingBetTicket == */
    INSERT IGNORE INTO DCS_DataTrace.MissingBetTicket(TransDate, CustID, SubscriberID, CreatedTime)
    SELECT 	lv_MaxTransDate AS TransDate
		,	tmp_trans.CustID
		,	tmp_trans.SubscriberID
        ,	lv_CurrentDatetime AS CreatedTime
    FROM Temp_LoginTransaction AS tmp_trans
		LEFT JOIN Temp_BetTicket AS tmp_bt ON tmp_bt.CustID = tmp_trans.CustID
		LEFT JOIN DCS_DataTrace.MissingBetTicket AS mbt ON mbt.TransDate = lv_MaxTransDate AND mbt.CustID = tmp_trans.CustID
    WHERE tmp_bt.ID IS NULL
		AND mbt.ID IS NULL;
    
END$$
DELIMITER ;
