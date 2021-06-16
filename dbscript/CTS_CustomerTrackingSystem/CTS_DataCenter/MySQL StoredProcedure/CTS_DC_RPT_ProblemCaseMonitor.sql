/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RPT_ProblemCaseMonitor`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RPT_ProblemCaseMonitor`(
		IN ip_FromDate	DATETIME
	,	IN ip_ToDate	DATETIME
    ,	IN ip_SubscriberIDList	VARCHAR(2000)
    ,	IN ip_ProblemCaseIDList	VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20210612@Casey.Huynh
		Task:  Get Prolem Case Report [RedmineID: #156464]
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20210612@Casey.Huynh: Created [RedmineID: #156464]
		Param's Explanation (filtered by):
            - ip_SubscriberList: SubscriberID List.  (0: All Subscriber, OR '1,2,3' list of SubscriberID)
            - ip_ProblemCaseList: ProblemCaseID List map to Staticlist (ListID = 12) (0: All ProblemCase, OR '1,2,3' list of ProblemCaseID)
		Example: CALL CTS_DC_RPT_ProblemCaseMonitor('2021-06-01','2021-06-20','0','1,3,9');
	*/ 
    DECLARE lv_StaticListID INT;
    DECLARE lv_Robot INT DEFAULT 1;
    DECLARE lv_GroupBetting INT DEFAULT 2;
    DECLARE lv_SuspiciousAssociation INT DEFAULT 3;
    DECLARE lv_ProPunter INT  DEFAULT 9;
    DECLARE lv_IsAllSubscriber TINYINT DEFAULT 0;
    DECLARE lv_IsAllProblemCase TINYINT DEFAULT 0;
    
    #==============================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;
    CREATE TEMPORARY TABLE Temp_Subscriber
    (
			SubscriberID	INT
        ,	SubscriberName	VARCHAR(200)
    );
	
	DROP TEMPORARY TABLE IF EXISTS Temp_ProblemCase;
    CREATE TEMPORARY TABLE Temp_ProblemCase
    (
			ProblemCaseID	SMALLINT UNSIGNED
		,	ProblemCaseName	VARCHAR(100)
    );
	#====GET Subscriber List=========================================
	CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_SubscriberIDList, ',', 'INT UNSIGNED');
    
    SELECT 1 INTO lv_IsAllSubscriber FROM TempItemTable WHERE Item = 0;
    
	IF lv_IsAllSubscriber = 1 THEN 
		INSERT INTO Temp_Subscriber(SubscriberID, SubscriberName)
        SELECT 	sub.SubscriberID
			,	sub.SubscriberName
        FROM	CTS_Admin.Subscriber AS sub;  
    ELSE
		INSERT INTO Temp_Subscriber(SubscriberID, SubscriberName)
        SELECT 	sub.SubscriberID
			,	sub.SubscriberName
        FROM	TempItemTable AS tmp
			INNER JOIN CTS_Admin.Subscriber AS sub ON tmp.Item = sub.SubscriberID;  
	END IF;
    
    #====GET ProblemCase List=======================================================
    CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_ProblemCaseIDList, ',', 'SMALLINT');
    
	SELECT 1 INTO lv_IsAllProblemCase FROM TempItemTable WHERE Item = 0;
    
    IF (lv_IsAllProblemCase = 1) THEN
		INSERT INTO Temp_ProblemCase(ProblemCaseID, ProblemCaseName)
        SELECT sl.ItemID, sl.ItemName
        FROM CTS_DataCenter.StaticList AS sl
        WHERE ListID = 12;
	ELSE 
		INSERT INTO Temp_ProblemCase(ProblemCaseID, ProblemCaseName)
        SELECT sl.ItemID, sl.ItemName
        FROM TempItemTable AS tmp
			INNER JOIN CTS_DataCenter.StaticList AS sl ON tmp.Item = sl.ItemID
        WHERE ListID = 12;
    END IF;

	SELECT 	
			tmp.CTSCustID
        ,	tmp.UserName
		,	tmp.SubscriberName        
		,	MAX(tmp.Robot) AS 'Robot'
		,	MAX(tmp.SuspiciousAssociation) AS 'SuspiciousAssociation'
		,	MAX(tmp.ProPunter) AS 'ProPunter'
	FROM (
		SELECT	cus.UserName, cus.CTSCustID, tmpSub.SubscriberName
				, (CASE WHEN pcm.ProblemCaseID = lv_Robot THEN 1 ELSE 0 END) 'Robot'
				, (CASE WHEN pcm.ProblemCaseID = lv_SuspiciousAssociation THEN 1 ELSE 0 END) 'SuspiciousAssociation'
				, (CASE WHEN pcm.ProblemCaseID = lv_ProPunter THEN 1 ELSE 0 END) 'ProPunter'
		FROM	CTS_DataCenter.ProblemCaseMonitor AS pcm
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON pcm.CustID = cus.CustID AND pcm.CustSubID = cus.CustSubID
			INNER JOIN Temp_Subscriber AS tmpSub ON cus.SubscriberID = tmpSub.SubscriberID
			INNER JOIN Temp_ProblemCase AS tmpPlc ON tmpPlc.ProblemCaseID = pcm.ProblemCaseID
		WHERE	pcm.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
				) AS tmp
   GROUP BY tmp.UserName, tmp.SubscriberName, tmp.CTSCustID
   ORDER BY tmp.UserName;
    
END$$

DELIMITER ;