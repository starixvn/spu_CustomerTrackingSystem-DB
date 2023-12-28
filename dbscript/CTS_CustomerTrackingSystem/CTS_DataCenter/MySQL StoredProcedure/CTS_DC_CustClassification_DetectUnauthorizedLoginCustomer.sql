-- Active: 1700468714672@@10.18.200.72@3306@CTS_DataCenter
/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DetectUnauthorizedLoginCustomer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_DetectUnauthorizedLoginCustomer`(
		IN ip_ListCustJson JSON
)
    SQL SECURITY INVOKER
BEGIN
	/* 
		Created:	20231226@Thomas.Nguyen
		Task :		Customer Classification - New CC 305/3005 System Detect Unauthorized Login
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20231226@Thomas.Nguyen: Created [Redmine ID: #197710] 
            
        Param's Explanation: 

		Example:
			-CALL CTS_DataCenter.CTS_DC_CustClassification_DetectUnauthorizedLoginCustomer

	*/
    DECLARE lv_FromDate		                DATE;
	DECLARE lv_ToDate		                DATE;
    DECLARE lv_SubSourceID_DirectAPI		TINYINT DEFAULT(1);
	DECLARE lv_SubSourceID_OddsFeed			TINYINT DEFAULT(2);
    DECLARE lv_Percentage_Threshold         DECIMAL(6,2) DEFAULT(50);

    SET lv_ToDate	= CURRENT_DATE();
    SET lv_FromDate = DATE_ADD(lv_ToDate, INTERVAL -90 DAY);

    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE 		Temp_Customer (
		 	CustID			BIGINT UNSIGNED		
         ,  CTSCustID 		BIGINT UNSIGNED
         ,  FirstBetDate    DATETIME
         ,  SubscriberID	INT
         ,	PRIMARY KEY PK_Temp_Customer(CustID)
         ,	INDEX IX_Temp_Customer_CTSCustID(CTSCustID)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_CustAccountID;
    CREATE TEMPORARY TABLE Temp_CustAccountID(
                AccountID	BIGINT UNSIGNED PRIMARY KEY 
            ,	CTSCustID	BIGINT UNSIGNED 
            ,	INDEX		IX_Temp_CustAccountID(CTSCustID)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_CustLogTransInfo;
	CREATE TEMPORARY TABLE 		Temp_CustLogTransInfo (
			CTSCustID 						    BIGINT UNSIGNED PRIMARY KEY
		,	CountLogin						    INT DEFAULT 0
        ,	CountBotTrans					    INT DEFAULT 0
        ,	CountInvalidBrowserTrans		    INT DEFAULT 0
        ,   BotTransPercentage                  DECIMAL(6,2)
        ,   InvalidBrowserInfoTransPercentage   DECIMAL(6,2)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_CustUnauthorizedLogin;
	CREATE TEMPORARY TABLE 		Temp_CustUnauthorizedLogin (
			CTSCustID 						    BIGINT UNSIGNED PRIMARY KEY
        ,   FirstBetDate                        DATETIME
        ,	CountBotTrans					    INT DEFAULT 0
        ,	CountInvalidBrowserTrans		    INT DEFAULT 0
        ,   BotTransPercentage                  DECIMAL(6,2)
        ,   InvalidBrowserInfoTransPercentage   DECIMAL(6,2)
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_CustAccLogTransInfo;
    CREATE TEMPORARY TABLE 		Temp_CustAccLogTransInfo (
            AccountID						BIGINT UNSIGNED PRIMARY KEY
        ,	CTSCustID 						BIGINT UNSIGNED
        ,	CountLogin						INT DEFAULT 0
        ,	CountBotTrans					INT DEFAULT 0
        ,	CountInvalidBrowserTrans		INT DEFAULT 0
        ,	INDEX		IX_Temp_CustAccLogTransInfo(CTSCustID)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_LoginTransactionSummary;
    CREATE TEMPORARY TABLE Temp_LoginTransactionSummary(
                AccountID	BIGINT UNSIGNED PRIMARY KEY
            ,	TotalTrans	INT UNSIGNED
            ,	Flagged		SMALLINT
            /*,	INDEX		IX_Temp_LoginTransactionSummary(AccountID)*/
    );

    INSERT IGNORE INTO Temp_Customer(CustID, CTSCustID, FirstBetDate, SubscriberID)
    SELECT tmp.CustID
        ,   cus.CTSCustID
        ,   tmp.FirstBetDate
        ,   cus.SubscriberID
    FROM JSON_TABLE(ip_ListCustJson,
                        "$[*]" COLUMNS (CustID          BIGINT        UNSIGNED PATH "$.CustID"
                                    ,   FirstBetDate    DATETIME               PATH "$.FirstBetDate"                                           
                                )) AS tmp
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID;

    INSERT IGNORE INTO Temp_CustAccountID(CTSCustID, AccountID)
    SELECT tmp.CTSCustID, acc.AccountID
    FROM Temp_Customer AS tmp
        INNER JOIN CTS_DataCenter.CustDCSAccount AS acc ON acc.CTSCustID = tmp.CTSCustID
        LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = tmp.SubscriberID AND sub.SubscriberSourceID IN (lv_SubSourceID_DirectAPI, lv_SubSourceID_OddsFeed)
    WHERE sub.SubscriberSourceID IS NULL;

    INSERT IGNORE INTO Temp_LoginTransactionSummary(AccountID, TotalTrans, Flagged)
    SELECT tmp.AccountID, ls.TotalTrans, ls.Flagged
    FROM Temp_CustAccountID AS tmp
        INNER JOIN DCS_DataTrace.LoginTransactionSummary AS ls ON ls.AccountID = tmp.AccountID AND ls.TransDate BETWEEN lv_FromDate AND lv_ToDate;

    INSERT IGNORE INTO Temp_CustAccLogTransInfo(CTSCustID, AccountID)
    SELECT tmp.CTSCustID, tmp.AccountID
    FROM Temp_CustAccountID AS tmp;

/*    INSERT IGNORE INTO Temp_CustAccLogTransInfo(CTSCustID, AccountID, CountLogin)
    SELECT tmp.CTSCustID, tmp.AccountID, SUM(sm.TotalLogin)
    FROM Temp_CustAccountID AS tmp
        INNER JOIN DCS_DataCenter.SumAccountLogin AS sm ON sm.AccountID = tmp.AccountID AND sm.TransDate BETWEEN lv_FromDate AND lv_ToDate
    GROUP BY tmp.CTSCustID, tmp.AccountID;*/
 
    UPDATE Temp_CustAccLogTransInfo AS tmp
    SET tmp.CountLogin = IFNULL((SELECT SUM(sm.TotalLogin)
                                FROM DCS_DataCenter.SumAccountLogin AS sm
                                WHERE sm.AccountID = tmp.AccountID AND sm.TransDate BETWEEN lv_FromDate AND lv_ToDate
                                GROUP BY sm.AccountID),0);

    UPDATE Temp_CustAccLogTransInfo AS tmp
    SET tmp.CountLogin = IFNULL((SELECT SUM(ls.TotalTrans) 
                                FROM Temp_LoginTransactionSummary AS ls
                                WHERE ls.AccountID = tmp.AccountID
                                GROUP BY ls.AccountID),tmp.CountLogin);
    
    WITH _TransCountInfo AS (
                SELECT ls.AccountID
                        ,SUM(CASE WHEN st.GroupID = 2 THEN ls.TotalTrans ELSE 0 END) AS CountInvalidBrowserTrans
                        ,SUM(CASE WHEN st.GroupID = 3 THEN ls.TotalTrans ELSE 0 END) AS CountBotTrans
                FROM Temp_LoginTransactionSummary AS ls
                    INNER JOIN DCS_DataCenter.StaticList AS st ON st.ItemID = ls.Flagged AND st.ListID = 1
                    INNER JOIN Temp_CustAccountID AS tmp ON tmp.AccountID = ls.AccountID
                GROUP BY ls.AccountID
    )
    UPDATE Temp_CustAccLogTransInfo AS tmp
        INNER JOIN _TransCountInfo tc ON tc.AccountID = tmp.AccountID
    SET tmp.CountBotTrans = tc.CountBotTrans
        , tmp.CountInvalidBrowserTrans = tc.CountInvalidBrowserTrans
    WHERE tc.CountBotTrans <> 0 OR tc.CountInvalidBrowserTrans <> 0;
    
    INSERT IGNORE INTO Temp_CustLogTransInfo(CTSCustID, CountLogin, CountBotTrans, CountInvalidBrowserTrans, BotTransPercentage, InvalidBrowserInfoTransPercentage)
    WITH CTE_Info AS (
        SELECT ct.CTSCustID AS CTSCustID
            , SUM(IFNULL(CountLogin,0)) AS CountLogin
            , SUM(IFNULL(CountBotTrans,0)) AS CountBotTrans
            , SUM(IFNULL(CountInvalidBrowserTrans,0)) AS CountInvalidBrowserTrans
        FROM Temp_CustAccLogTransInfo AS ct
        GROUP BY ct.CTSCustID
    )
    SELECT cte.CTSCustID, cte.CountLogin, cte.CountBotTrans, cte.CountInvalidBrowserTrans
            , ROUND((cte.CountBotTrans/cte.CountLogin)*100,2) AS BotTransPercentage
            , ROUND((cte.CountInvalidBrowserTrans/cte.CountLogin)*100,2) AS InvalidBrowserInfoTransPercentage
    FROM CTE_Info AS cte;

    INSERT IGNORE INTO Temp_CustUnauthorizedLogin(CTSCustID, FirstBetDate, CountBotTrans, CountInvalidBrowserTrans, BotTransPercentage, InvalidBrowserInfoTransPercentage)
    SELECT ct.CTSCustID, cus.FirstBetDate, ct.CountBotTrans, ct.CountInvalidBrowserTrans, ct.BotTransPercentage, ct.InvalidBrowserInfoTransPercentage
    FROM Temp_CustLogTransInfo AS ct
        INNER JOIN Temp_Customer AS cus ON cus.CTSCustID = ct.CTSCustID
    WHERE ct.BotTransPercentage > lv_Percentage_Threshold OR ct.InvalidBrowserInfoTransPercentage > lv_Percentage_Threshold;
    
    INSERT IGNORE INTO CTS_DataCenter.CustLoginInfoDetection(CTSCustID, CustID, FirstBetDate, Bot, InvalidBrowser, BotTransPercentage, InvalidBrowserInfoTransPercentage) 
    SELECT ct.CTSCustID, cus.CustID, cus.FirstBetDate, ct.CountBotTrans, ct.CountInvalidBrowserTrans, ct.BotTransPercentage, ct.InvalidBrowserInfoTransPercentage
    FROM Temp_CustUnauthorizedLogin AS ct;
    
    /*Return data*/
    SELECT CTSCustID
            , FirstBetDate
            , CountBotTrans AS Bot
            , CountInvalidBrowserTrans AS InvalidBrowser
            , BotTransPercentage AS BotPCT
            , InvalidBrowserInfoTransPercentage AS InvalidBrowserPCT
    FROM Temp_CustUnauthorizedLogin AS ct;

END$$
DELIMITER ;