/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transaction_GetLatest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetLatest`(
		IN ip_SubscriberId	INT
	, 	IN ip_Length		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Adam.Tran
		Task:		Get latest transactions 
		DB:			DCS_DataCenter
        
		Revisions:
			- 20210330@Adam.Tran: Created [Redmine ID: #140348]  
			- 20210412@Aries.Nguyen: Fix issue performance when filter all  [Redmine ID: #153009]
            - 20210629@Casey.Huynh: Return Flagged Value (Web will show type of robot) [Redmine ID: 157085]
			- 20211006@Aries.Nguyen: Fix issue performance when filter sub SM88  [Redmine ID: #162888]
			- 20211123@Aries.Nguyen: Fix issue performance when filter sub AlphaIBCIndo  [Redmine ID: #162888]
			- 20230411@Casey.Huynh: Tunning Performance  [Redmine ID: #186129]
            - 20230512@Jonas.Huynh: BOTD transactions [Redmine ID: 185792]
            - 20230524@Jonas.Huynh: Fix issue wrong data type [Redmine ID: 188680]
            
		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.DCS_DC_Transaction_GetLatest(1, 100);
	*/    
    DECLARE lv_Partition		VARCHAR(50);
    DECLARE	lv_TotalTrans		INT DEFAULT 0;
    DECLARE lv_LimitTrans		INT DEFAULT 0;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    CREATE TEMPORARY TABLE Temp_Transaction(	
			TransID			BIGINT UNSIGNED
        ,	AccountID		BIGINT UNSIGNED
        ,	SubscriberName	VARCHAR(50)
        ,	UserName		VARCHAR(50)
        ,	LoginID			VARCHAR(50)
        ,	CTSCustID		BIGINT UNSIGNED
		,	TransTime		DATETIME(4)     
		,	FirstDeviceCode	VARCHAR(64)
		,	IP				VARCHAR(50)
		,	Flagged			VARCHAR(200)
		,	Action			VARCHAR(100)
		,	ActionResult	VARCHAR(100)
		,	OS				VARCHAR(100)		
		,	Browser			VARCHAR(100)
		,	URLDetails		VARCHAR(250)
        
        ,	PRIMARY KEY PK_Temp_Transaction(AccountID, TransID)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Partition;
    CREATE TEMPORARY TABLE Temp_Partition(
			PartitionOrdinalPosition INT PRIMARY KEY
        ,	PartitionName	VARCHAR(100)
        
        ,	INDEX IX_Temp_Partition_PartitionName(PartitionName)
    );
    
    INSERT INTO Temp_Partition(PartitionOrdinalPosition, PartitionName)
    SELECT	p.Partition_Ordinal_Position
		,	p.Partition_Name 
    FROM INFORMATION_SCHEMA.`PARTITIONS` AS p
    WHERE p.TABLE_SCHEMA = 'DCS_DataCenter' 
		AND p.`TABLE_NAME` = 'Transaction07';    
	
    SELECT	tmp.PartitionName
    INTO lv_Partition
    FROM Temp_Partition AS tmp
    ORDER BY PartitionOrdinalPosition DESC
    LIMIT 1;
	
    SET lv_LimitTrans = ip_Length;
	WHILE (lv_LimitTrans > 0 AND lv_Partition IS NOT NULL) DO

        SET @sql = 	CONCAT("
		INSERT INTO Temp_Transaction(TransID, AccountID, SubscriberName, UserName, LoginID, CTSCustID, TransTime, FirstDeviceCode, IP, Flagged, Action, ActionResult, OS, Browser, URLDetails)
        SELECT	ts.TransID
			,	ts.AccountID
			,	sb.SubscriberName
			,	cus.UserName
			,	cus.UserName2 AS LoginID
			,	cus.CTSCustID
			,	ts.TransTime
			,	ts.FirstDeviceCode
			,	ts.IP
			,	s.ItemName AS Flagged
			,	ar.Action
			,	ar.ActionResult
			,	ua.OS
			,	ua.Browser
			,	ur.URLDetails 
		FROM DCS_DataCenter.Transaction07 PARTITION(",lv_Partition,") AS ts
			INNER JOIN CTS_DataCenter.CustDCSAccount AS ca ON ts.AccountID = ca.AccountID AND ca.SubscriberID = ts.SubscriberID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON ca.CTSCustID = cus.CTSCustID 
			LEFT JOIN DCS_DataCenter.UserAgent AS ua ON ts.UserAgentKey = ua.UserAgentKey
			LEFT JOIN DCS_DataCenter.ActionResult AS ar ON ts.ActionResultID = ar.ActionResultID
			LEFT JOIN DCS_DataCenter.URL AS ur ON ts.URLID = ur.URLID AND ts.SubscriberID = ur.SubscriberID
            LEFT JOIN CTS_Admin.Subscriber AS sb ON cus.SubscriberID = sb.SubscriberID		
            LEFT JOIN DCS_DataCenter.StaticList AS s ON s.ListID = 1 AND s.ItemID = ts.Flagged AND s.Status = 1
		WHERE ts.SubscriberID = ",ip_SubscriberId," OR ",ip_SubscriberId," = -1
        ORDER BY ts.TransTime DESC
        LIMIT ",lv_LimitTrans);
        
        PREPARE stmt1 FROM  @sql;
		EXECUTE stmt1; 
		DEALLOCATE PREPARE stmt1;
        
		SET lv_TotalTrans = (SELECT COUNT(1) FROM Temp_Transaction);
        
        SET lv_LimitTrans = ip_Length - lv_TotalTrans;
        
        DELETE tmp
        FROM Temp_Partition AS tmp
        WHERE tmp.PartitionName = lv_Partition;
        
        SET lv_Partition = (SELECT	tmp.PartitionName
							FROM Temp_Partition AS tmp
							ORDER BY PartitionOrdinalPosition DESC
							LIMIT 1);    
		
    END WHILE;
    
    SELECT	tmpTs.UserName
		,	tmpTs.LoginID
		,	tmpTs.SubscriberName
		,	tmpTs.CTSCustID
		,	tmpTs.TransTime            
		,	tmpTs.FirstDeviceCode	
		,	tmpTs.IP
		,	tmpTs.Flagged
		,	tmpTs.Action
		,	tmpTs.ActionResult
		,	tmpTs.OS
		,	tmpTs.Browser
		,	tmpTs.URLDetails
		,	tmpTs.AccountID
		,	tmpTs.TransID
	FROM Temp_Transaction AS tmpTs
    ORDER BY tmpTs.TransTime DESC;           

END$$

DELIMITER ;
