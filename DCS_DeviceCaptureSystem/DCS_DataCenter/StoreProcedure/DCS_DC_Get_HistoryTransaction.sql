DELIMITER $$
#DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_Get_HistoryTransaction$$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_Get_HistoryTransaction`(
	IN ip_FromDate DATETIME, 
	IN ip_ToDate DATETIME, 
	IN ip_SubscriberId INT, 
    IN ip_CTSCustId BIGINT,
    IN ip_PageSize INT,
    IN ip_PageNumber INT,
    OUT op_TotalItem INT)
proc_label: BEGIN
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
			TransID			BIGINT(20),
			TransTime	 	DATETIME, 
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;  
    
    CREATE TEMPORARY TABLE Temp_Account
	(
			AccountID	 	BIGINT(20)      
    );
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ; 
	
    IF ISNULL(ip_FromDate) OR ISNULL(ip_ToDate) THEN
		SELECT Count(TransID) INTO op_TotalItem FROM Temp_History_Transaction;
    
		SELECT 	TransID			,
				DATE_FORMAT(TransTime, "%M %d, %y")	as TransTime 	, 
				DeviceID 		,
				IP				,
				IPID			,
				CASE
					WHEN Flagged = 5 THEN 'Robot (Browserless - Empty Token)'
					WHEN Flagged = 6 THEN 'Robot (Browserless - Empty Analysis)'
					WHEN Flagged = 7 THEN 'Robot (Browserless - Disabled JS)'
					WHEN Flagged = 8 THEN 'Robot (Browserless - Invalid Analysis)'
					WHEN Flagged = 9 THEN 'Robot (Browserless - Invalid Token)'
					WHEN Flagged = 10 THEN 'Robot (Browserless - Invalid Device Code)'
					ELSE 'Green'
				END AS Flagged	,
				Action			,
				ActionResult	,
				OSName			,
				BrowserName		,
				URL				
		FROM Temp_History_Transaction       
		LIMIT ip_PageNumber, ip_PageSize;
    
		LEAVE proc_label;
    END IF;    
    
    SELECT LastArchivedDate INTO @MoveTransTime 
		FROM DCS_DataCenter.ArchiveStatus 
        WHERE ArchiveID = 1;       
    
    INSERT INTO Temp_Account 
		SELECT cusAcc.AccountID 
			FROM CTS_DataCenter.CustDCSAccount cusAcc 
			WHERE cusAcc.CTSCustID = ip_CTSCustId	
					AND cusAcc.SubscriberID = ip_SubscriberId;
    
    SET @MoveDate = Date(@MoveTransTime);
    SET @FromDate = Date(ip_FromDate);
    SET @ToDate = Date(ip_ToDate);
    
    IF @MoveDate <= @FromDate THEN # scan 07
		INSERT INTO Temp_History_Transaction(TransID, TransTime, DeviceID, IP, IPID, Flagged, Action, ActionResult, OSName, BrowserName, URL)    
			SELECT 	trs.TransID,
					trs.TransTime,  
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
			LEFT JOIN DCS_DataCenter.UserAgent uag 
					ON trs.UserAgentKey = uag.UserAgentKey
			LEFT JOIN DCS_DataCenter.ActionResult ar 
					ON trs.ActionResultID = ar.ActionResultID
			LEFT JOIN DCS_DataCenter.URL ur 
					ON trs.URLID = ur.URLID AND trs.SubscriberID = ur.SubscriberID
			WHERE trs.AccountID IN (SELECT AccountID FROM Temp_Account)
				AND trs.SubscriberID = ip_SubscriberId 
				AND trs.CreatedDate BETWEEN @FromDate And @ToDate;
        
    ELSEIF @MoveDate >= @ToDate THEN # scan bk
    
		INSERT INTO Temp_History_Transaction(TransID, TransTime, DeviceID, IP, IPID, Flagged, Action, ActionResult, OSName, BrowserName, URL)    
			SELECT 	trs.TransID,
					trs.TransTime,  
					trs.FirstDeviceCode, 
					trs.IP, 
					trs.IPID,
					trs.Flagged, 
					ar.Action, 
					ar.ActionResult, 
					uag.OS, 
					uag.Browser, 
					ur.URLDetails
			FROM DCS_DataCenter.Transaction_BK01 trs
			LEFT JOIN DCS_DataCenter.UserAgent uag 
					ON trs.UserAgentKey = uag.UserAgentKey
			LEFT JOIN DCS_DataCenter.ActionResult ar 
					ON trs.ActionResultID = ar.ActionResultID
			LEFT JOIN DCS_DataCenter.URL ur 
					ON trs.URLID = ur.URLID AND trs.SubscriberID = ur.SubscriberID
			WHERE trs.AccountID IN (SELECT AccountID FROM Temp_Account)
				AND trs.SubscriberID=ip_SubscriberId 
				AND trs.CreatedDate BETWEEN @FromDate And @ToDate;	
    ELSE # scan 07 & bk
		
		INSERT INTO Temp_History_Transaction(TransID, TransTime, DeviceID, IP, IPID, Flagged, Action, ActionResult, OSName, BrowserName, URL)   
			SELECT 	trs.TransID,
					trs.TransTime,  
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
			LEFT JOIN DCS_DataCenter.UserAgent uag 
					ON trs.UserAgentKey = uag.UserAgentKey
			LEFT JOIN DCS_DataCenter.ActionResult ar 
					ON trs.ActionResultID = ar.ActionResultID
			LEFT JOIN DCS_DataCenter.URL ur 
					ON trs.URLID = ur.URLID AND trs.SubscriberID = ur.SubscriberID
			WHERE trs.AccountID IN (SELECT AccountID FROM Temp_Account)
				AND trs.SubscriberID=ip_SubscriberId 
				AND trs.CreatedDate BETWEEN DATE_ADD(@MoveDate, INTERVAL 1 DAY) And @ToDate;         
		
        
        INSERT INTO Temp_History_Transaction(TransID, TransTime, DeviceID, IP, IPID, Flagged, Action, ActionResult, OSName, BrowserName, URL)   
			SELECT 	trs.TransID,
					trs.TransTime,  
					trs.FirstDeviceCode, 
					trs.IP, 
					trs.IPID,
					trs.Flagged, 
					ar.Action, 
					ar.ActionResult, 
					uag.OS, 
					uag.Browser, 
					ur.URLDetails
			FROM DCS_DataCenter.Transaction_BK01 trs
			LEFT JOIN DCS_DataCenter.UserAgent uag 
					ON trs.UserAgentKey = uag.UserAgentKey
			LEFT JOIN DCS_DataCenter.ActionResult ar 
					ON trs.ActionResultID = ar.ActionResultID
			LEFT JOIN DCS_DataCenter.URL ur 
					ON trs.URLID = ur.URLID AND trs.SubscriberID = ur.SubscriberID
			WHERE trs.AccountID IN (SELECT AccountID FROM Temp_Account)
				AND trs.SubscriberID=ip_SubscriberId 
				AND trs.CreatedDate BETWEEN @FromDate And @MoveDate;        
	END IF; 
     
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    SELECT Count(TransID) INTO op_TotalItem FROM Temp_History_Transaction;
    
    SELECT 	TransID			,
			TransTime	 	, 
            DeviceID 		,
            IP				,
            IPID			,
            CASE
				WHEN Flagged = 5 THEN 'Robot (Browserless - Empty Token)'
                WHEN Flagged = 6 THEN 'Robot (Browserless - Empty Analysis)'
                WHEN Flagged = 7 THEN 'Robot (Browserless - Disabled JS)'
                WHEN Flagged = 8 THEN 'Robot (Browserless - Invalid Analysis)'
                WHEN Flagged = 9 THEN 'Robot (Browserless - Invalid Token)'
                WHEN Flagged = 10 THEN 'Robot (Browserless - Invalid Device Code)'
                ELSE 'Green'
			END AS Flagged	,
            Action			,
            ActionResult	,
            OSName			,
            BrowserName		,
            URL				
	FROM Temp_History_Transaction   
    ORDER BY TransTime
    LIMIT ip_PageNumber, ip_PageSize;    
END$$
DELIMITER ;
