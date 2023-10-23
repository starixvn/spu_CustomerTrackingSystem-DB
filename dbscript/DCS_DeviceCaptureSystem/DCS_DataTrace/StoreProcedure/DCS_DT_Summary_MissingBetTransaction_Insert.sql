/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_MissingBetTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_MissingBetTransaction_Insert`(
        IN ip_TransDate     DATE
	,	IN ip_FromID   		BIGINT UNSIGNED
    ,   IN ip_ToID     		BIGINT UNSIGNED
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
        CALL DCS_DataTrace.DCS_DT_Summary_MissingBetTransaction_Insert('2023-10-01', 1, 2);
	*/
    DECLARE CONST_SUMMARY_MAXTRANSDATE INT DEFAULT 2;
    DECLARE CONST_MISSINGBETTRANSACTION_TYPE SMALLINT DEFAULT 2;
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransactionSummary;
	DROP TEMPORARY TABLE IF EXISTS Temp_BetTransactionSummary;
    
	CREATE TEMPORARY TABLE Temp_LoginTransactionSummary(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		, 	CustID					INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_LoginTransactionSummary_CustID` (`CustID`)
		,	INDEX `IX_Temp_LoginTransactionSummary_SubscriberID_CustID` (`SubscriberID`, `CustID`)
	);
    
	CREATE TEMPORARY TABLE Temp_BetTransactionSummary(
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		, 	CustID					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID			INT UNSIGNED DEFAULT NULL
		,	PRIMARY KEY (`ID`)
		,	INDEX `IX_Temp_BetTransactionSummary_CustID` (`CustID`)
	);
    
    INSERT INTO Temp_LoginTransactionSummary(SubscriberID, CustID)
    SELECT 	DISTINCT 
			trans.SubscriberID
		,	cts.CustID
    FROM DCS_DataTrace.LoginTransactionSummary AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
    WHERE trans.ID BETWEEN ip_FromID AND ip_ToID
		AND trans.TransDate = ip_TransDate
        AND cts.RoleID = 1;
    
    INSERT INTO Temp_BetTransactionSummary(SubscriberID, CustID)
    SELECT 	DISTINCT
			cts.SubscriberID
		,	bt.CustID
    FROM DCS_DataTrace.BetTransactionSummary AS bt
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CustID = bt.CustID
    WHERE bt.TransDate = ip_TransDate;
    
    /* == MissingTransaction == */
    DELETE tmp_trans
    FROM Temp_LoginTransactionSummary AS tmp_trans
		INNER JOIN Temp_BetTransactionSummary AS tmp_bt ON tmp_bt.CustID = tmp_trans.CustID;
        
    DELETE tmp_trans
    FROM Temp_LoginTransactionSummary AS tmp_trans
		INNER JOIN DCS_DataTrace.MemberMissingTransaction AS mt ON mt.TransDate = ip_TransDate 
														AND mt.SubscriberID = tmp_trans.SubscriberID 
                                                        AND mt.MissingTransactionType = CONST_MISSINGBETTRANSACTION_TYPE
														AND mt.CustID = tmp_trans.CustID;
    
    INSERT IGNORE INTO DCS_DataTrace.MemberMissingTransaction(MissingTransactionType, TransDate, SubscriberID, CustID, CreatedTime)
    SELECT 	CONST_MISSINGBETTRANSACTION_TYPE AS MissingTransactionType
		,	ip_TransDate AS TransDate
		,	SubscriberID
		,	CustID
        ,	lv_CurrentDatetime AS CreatedTime
    FROM Temp_LoginTransactionSummary;
    
END$$
DELIMITER ;
