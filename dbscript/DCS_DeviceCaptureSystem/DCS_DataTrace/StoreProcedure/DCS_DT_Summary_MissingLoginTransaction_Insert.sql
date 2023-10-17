/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_MissingLoginTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_MissingLoginTransaction_Insert`(
        IN ip_FromID   BIGINT UNSIGNED
    ,   IN ip_ToID     BIGINT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231009@Jonathan.Doan
	Task : Insert MissingLoginTransaction by range ID
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231009@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Summary_MissingLoginTransaction_Insert(1, 2);
	*/
    DECLARE CONST_SUMMARY_MAXTRANSDATE INT DEFAULT 2;
    DECLARE CONST_MISSINGLOGINTRANSACTION_TYPE SMALLINT DEFAULT 0;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_MaxTransDate DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransDate = (SELECT DATE(VValue) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_SUMMARY_MAXTRANSDATE);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_BetTransactionSummary;
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransactionSummary;
    
	CREATE TEMPORARY TABLE Temp_BetTransactionSummary(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		, 	CustID					INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_BetTransactionSummary_CustID` (`CustID`)
	);
    
	CREATE TEMPORARY TABLE Temp_LoginTransactionSummary(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		, 	CustID					INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_LoginTransactionSummary_CustID` (`CustID`)
	);
    
    INSERT INTO Temp_BetTransactionSummary(SubscriberID, CustID)
    SELECT 	DISTINCT
			cts.SubscriberID
        ,	bt.CustID
    FROM DCS_DataTrace.BetTransactionSummary AS bt
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CustID = bt.CustID
    WHERE bt.ID BETWEEN ip_FromID AND ip_ToID
		AND bt.TransDate = lv_MaxTransDate;
    
    INSERT INTO Temp_LoginTransactionSummary(SubscriberID, CustID)
    SELECT 	DISTINCT
			trans.SubscriberID
		,	cts.CustID
    FROM DCS_DataTrace.LoginTransactionSummary AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
    WHERE trans.TransDate = lv_MaxTransDate
		AND cts.RoleID = 1;
    
    /* == MissingTransaction == */    
    INSERT IGNORE INTO DCS_DataTrace.MissingTransaction(MissingType, TransDate, SubscriberID, CustID, CreatedTime)
    SELECT 	CONST_MISSINGLOGINTRANSACTION_TYPE AS MissingType
		,	lv_MaxTransDate AS TransDate
		,	tmp_bt.SubscriberID
		,	tmp_bt.CustID
        ,	lv_CurrentDatetime AS CreatedTime
    FROM Temp_BetTransactionSummary AS tmp_bt
		LEFT JOIN Temp_LoginTransactionSummary AS tmp_trans ON tmp_trans.CustID = tmp_bt.CustID
		LEFT JOIN DCS_DataTrace.MissingTransaction AS mlt ON mlt.MissingType = CONST_MISSINGLOGINTRANSACTION_TYPE AND mlt.TransDate = lv_MaxTransDate AND mlt.CustID = tmp_bt.CustID
    WHERE tmp_trans.ID IS NULL
		AND mlt.ID IS NULL;
    
END$$
DELIMITER ;
