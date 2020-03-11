DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_Get_HistoryTransaction`(
	IN ip_FromDate DATETIME, 
	IN ip_ToDate DATETIME, 
	IN ip_SubscriberId INT, 
    IN ip_CTSCustId BIGINT)
BEGIN
	/*
		Created:	20200311@Terry
		Task:		Get history transaction by date [Redmine ID: 130074]
		DB:			DCS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL DCS_DC_Get_History_Transaction ()
	*/ 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_History_Transaction;  
	CREATE TEMPORARY TABLE Temp_History_Transaction
	(
			TransTime	 	TIMESTAMP(4), 
            DeviceID 		VARCHAR(64),
            IP				VARCHAR(50),
            IPID			DECIMAL(50,0),
            Flagged			SMALLINT(6),
            Action			VARCHAR(100),
            ActionResult	VARCHAR(100),
            OSName			VARCHAR(100),
            BrowserName		VARCHAR(100),
            URL				VARCHAR(100)           
    );
       
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ; 
	
    SELECT datediff(ip_ToDate, ip_FromDate) INTO @numOfDays;    
    SELECT cusAcc.AccountID INTO @AccountId FROM CTS_DataCenter.CustDCSAccount cusAcc WHERE cusAcc.CTSCustID = ip_CTSCustId AND cusAcc.SubscriberID = ip_SubscriberId;
    
    IF @numOfDays > 7 THEN
		INSERT INTO Temp_History_Transaction(
				TransTime	 	, 
				DeviceID 		,
				IP				,
                IPID			,
				Flagged			,
				Action			,
				ActionResult	,
				OSName			,
				BrowserName		,
				URL				
		)    
		SELECT 	trs.TransTime,  
				trs.FirstDeviceCode, 
				trs.IP, 
                trs.IPID,
				trs.Flagged, 
				ar.Action, 
				ar.ActionResult, 
				uag.OS, 
				uag.Browser, 
				ur.URLDetails
		FROM DCS_DataCenter.Transaction_BK trs
		INNER JOIN DCS_DataCenter.UserAgent uag 
				ON trs.UserAgentKey = uag.UserAgentKey
		INNER JOIN DCS_DataCenter.ActionResult ar 
				ON trs.ActionResultID = ar.ActionResultID
		INNER JOIN DCS_DataCenter.URL ur 
				ON trs.URLID = ur.URLID AND trs.SubscriberID = ur.SubscriberID
		WHERE trs.AccountID = @AccountId 
			AND trs.SubscriberID=ip_SubscriberId 
			AND trs.CreatedDate BETWEEN ip_FromDate And ip_ToDate;	
    ELSE
		INSERT INTO Temp_History_Transaction(
			TransTime	 	, 
            DeviceID 		,
            IP				,
			IPID			,
            Flagged			,
            Action			,
            ActionResult	,
            OSName			,
            BrowserName		,
            URL				
    )    
    SELECT 	trs.TransTime,  
			trs.FirstDeviceCode, 
			trs.IP, 
            trs.IPID,
			trs.Flagged, 
			ar.Action, 
			ar.ActionResult, 
			uag.OS, 
			uag.Browser, 
			ur.URLDetails
    FROM DCS_DataCenter.Transaction07 trs 
    INNER JOIN DCS_DataCenter.UserAgent uag 
			ON trs.UserAgentKey = uag.UserAgentKey
    INNER JOIN DCS_DataCenter.ActionResult ar 
			ON trs.ActionResultID = ar.ActionResultID
    INNER JOIN DCS_DataCenter.URL ur 
			ON trs.URLID = ur.URLID AND trs.SubscriberID = ur.SubscriberID
    WHERE trs.AccountID = @AccountId 
		AND trs.SubscriberID=ip_SubscriberId 
		AND trs.CreatedDate BETWEEN ip_FromDate And ip_ToDate;	
    END IF;       
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    SELECT TransTime	 	, 
            DeviceID 		,
            IP				,
            IPID			,
            Flagged			,
            Action			,
            ActionResult	,
            OSName			,
            BrowserName		,
            URL				
	FROM Temp_History_Transaction;
END$$
DELIMITER ;
