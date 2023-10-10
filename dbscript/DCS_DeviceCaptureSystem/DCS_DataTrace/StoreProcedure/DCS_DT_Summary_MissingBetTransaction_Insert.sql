/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_MissingBetTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_MissingBetTransaction_Insert`(
        IN ip_FromID   BIGINT UNSIGNED
    ,   IN ip_ToID     BIGINT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231009@Jonathan.Doan
	Task : Insert MissingBetTransaction by range ID
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231009@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Summary_MissingBetTransaction_Insert(1, 2);
	*/
    DECLARE CONST_SUMMARY_MAXTRANSDATE INT DEFAULT 2;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_MaxTransDate DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransDate = (SELECT DATE(VValue) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_SUMMARY_MAXTRANSDATE);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransactionSummary;
	DROP TEMPORARY TABLE IF EXISTS Temp_BetTransactionSummary;
    
	CREATE TEMPORARY TABLE Temp_LoginTransactionSummary(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_LoginTransactionSummary_CustID` (`CustID`)
	);
    
	CREATE TEMPORARY TABLE Temp_BetTransactionSummary(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `UX_Temp_BetTransactionSummary_CustID` (`CustID`)
	);
    
    INSERT INTO Temp_LoginTransactionSummary(CustID, SubscriberID)
    SELECT 	DISTINCT 
			cts.CustID
        ,	trans.SubscriberID
    FROM DCS_DataTrace.LoginTransactionSummary AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
    WHERE trans.ID BETWEEN ip_FromID AND ip_ToID
		AND trans.TransDate = lv_MaxTransDate
        AND cts.RoleID = 1;
    
    INSERT INTO Temp_BetTransactionSummary(CustID, SubscriberID)
    SELECT 	DISTINCT
			bt.CustID
        ,	cts.SubscriberID
    FROM DCS_DataTrace.BetTransactionSummary AS bt
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CustID = bt.CustID
    WHERE bt.TransDate = lv_MaxTransDate;
    
    /* == MissingBetTransactionSummary == */
    INSERT IGNORE INTO DCS_DataTrace.MissingBetTransaction(TransDate, SubscriberID, CustID, CreatedTime)
    SELECT 	lv_MaxTransDate AS TransDate
		,	tmp_trans.SubscriberID
		,	tmp_trans.CustID
        ,	lv_CurrentDatetime AS CreatedTime
    FROM Temp_LoginTransactionSummary AS tmp_trans
		LEFT JOIN Temp_BetTransactionSummary AS tmp_bt ON tmp_bt.CustID = tmp_trans.CustID
		LEFT JOIN DCS_DataTrace.MissingBetTransaction AS mbt ON mbt.TransDate = lv_MaxTransDate AND mbt.CustID = tmp_trans.CustID
    WHERE tmp_bt.ID IS NULL
		AND mbt.ID IS NULL;
    
END$$
DELIMITER ;
