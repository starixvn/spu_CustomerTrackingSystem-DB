/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_IncorrectData_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_IncorrectData_Get`(
		OUT op_IsContinue 	BIT
    )
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240102@Jonas.Huynh
		Task:		Enhance Monitoring Job [Redmine ID: 197999]
		DB:			CTS_DataCenter
		Original:

		Revisions:
            - 20240102@Jonas.Huynh: Creator [Redmine ID: 197999]
            - 20241213@Jonas.Huynh: Missing Customer [Redmine ID: 214157]
            
		Param's Explanation (filtered by):
		Example:
				set @op_IsContinue = 0;
				call CTS_DataCenter.CTS_DC_Monitoring_IncorrectData_Get(@op_IsContinue);
				select @op_IsContinue;

	*/
    DECLARE CONST_BATCHSIZE							SMALLINT DEFAULT 5000;
    
    DECLARE CONST_MISSING_NEWCUSTOMER				TINYINT DEFAULT 2;
    DECLARE CONST_MISSING_REACTIVATEDCUSTOMER		TINYINT DEFAULT 50;
    
    DECLARE CONST_ISSUETYPEID_TOTALMISSINGCUST		TINYINT DEFAULT 4;
    
    DECLARE lv_LastScanID 			BIGINT UNSIGNED;
    DECLARE lv_MaxScanID	 		BIGINT UNSIGNED;
    DECLARE lv_CurrentNextScanID 	BIGINT UNSIGNED;
       
	DROP TEMPORARY TABLE IF EXISTS Temp_IncorrectData;    
	CREATE TEMPORARY TABLE Temp_IncorrectData(
			ID					BIGINT UNSIGNED
		,	IssueTypeID			SMALLINT UNSIGNED
		,	CustID				INT	UNSIGNED 
        ,	`Value`				BIGINT
        ,	TrackingInfo		VARCHAR(500)
        ,	CreatedTime			DATETIME
        ,	IsResolved			BIT(1) DEFAULT(0)
        ,	IsIssueTypeValid	BIT(1) DEFAULT(1)
        ,	KEY IX_Temp_IncorrectData_ID(ID)	
	);
       
    SELECT ParameterValue
	INTO lv_LastScanID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 151; 
    
    INSERT INTO Temp_IncorrectData(ID, CustID, `Value`, TrackingInfo, CreatedTime, IsResolved, IssueTypeID, IsIssueTypeValid)
    SELECT 		a.ID
			,	a.CustID
            ,	a.`Value`
            ,	a.TrackingInfo
            ,	a.CreatedTime
            ,	a.IsResolved
            ,	a.IssueTypeID
            ,	CASE WHEN s.ItemID IS NOT NULL THEN TRUE ELSE FALSE END AS IsIssueTypeValid
    FROM CTS_DataCenter.JobMonitoring_IncorrectData AS a
		LEFT JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 20 AND s.ItemID = a.IssueTypeID
	WHERE ID > lv_LastScanID
    ORDER BY ID ASC
    LIMIT CONST_BATCHSIZE;   
    
    SELECT MAX(ID) INTO lv_MaxScanID FROM CTS_DataCenter.JobMonitoring_IncorrectData;
    SELECT MAX(ID) INTO lv_CurrentNextScanID FROM Temp_IncorrectData;
    SET op_IsContinue = CASE WHEN lv_CurrentNextScanID < lv_MaxScanID AND lv_CurrentNextScanID IS NOT NULL THEN 1 ELSE 0 END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_IncorrectData2;    
    CREATE TEMPORARY TABLE Temp_IncorrectData2 LIKE Temp_IncorrectData;
        
	INSERT INTO Temp_IncorrectData2(ID, CustID, `Value`, TrackingInfo, CreatedTime, IsResolved, IssueTypeID,  IsIssueTypeValid)
    SELECT 		0
			,	NULL
            ,	COUNT(1)
            ,	NULL
            ,	NULL
            ,	0
            ,	CASE WHEN COUNT(1) > 0 THEN CONST_ISSUETYPEID_TOTALMISSINGCUST ELSE NULL END	
            ,	1
    FROM CTS_DataCenter.JobMonitoring_IncorrectData AS a
		INNER JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 20 
					AND s.ItemID = a.IssueTypeID
					AND s.ItemID IN (CONST_MISSING_NEWCUSTOMER, CONST_MISSING_REACTIVATEDCUSTOMER)
	WHERE a.IsResolved = 0;
       
	IF EXISTS (SELECT 1 FROM Temp_IncorrectData2 WHERE IssueTypeID IS NOT NULL) THEN
		INSERT INTO Temp_IncorrectData(ID, CustID, `Value`, TrackingInfo, CreatedTime, IsResolved, IssueTypeID, IsIssueTypeValid)
		SELECT ID, CustID, `Value`, TrackingInfo, CreatedTime, IsResolved, IssueTypeID, IsIssueTypeValid
		FROM Temp_IncorrectData2;
	END IF;
    
    SELECT ID, CustID, `Value`, TrackingInfo, CreatedTime, IsResolved, IssueTypeID,  IsIssueTypeValid
    FROM Temp_IncorrectData;
    
END$$
DELIMITER ;