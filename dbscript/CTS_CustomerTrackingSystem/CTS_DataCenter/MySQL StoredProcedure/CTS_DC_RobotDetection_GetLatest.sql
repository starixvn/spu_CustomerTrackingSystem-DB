/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotDetection_GetLatest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotDetection_GetLatest`(
		IN 	ip_RobotDetectionLastID		BIGINT UNSIGNED
	,	IN	ip_RobotImpervaLastLogID	BIGINT		
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220523@Long.Luu
		Task:		Get Latest Robot Info to push to CTS [Redmine ID: #172561]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20220523@Long.Luu: 		Created -  Robot Detection [Redmine ID: #172561]
			- 20230315@Victoria.Le:		Get Robot Imperva [Redmine ID: #184773]
            - 20230517@Casey.Huynh:		New Category for Robot OCRD [Redmine ID: #186991]
            
		Example:
			CALL CTS_DataCenter.CTS_DC_RobotDetection_GetLatest(@ip_LatestTimeAI:='2022-01-01 02:02:02.000', @ip_LatestTimeImperva:='2022-01-01 02:02:02.000');
	*/    
    
    DECLARE CONST_BATCHSIZE 			INT UNSIGNED DEFAULT(5000);
    DECLARE CONST_CATEGORYID_ROBOTUSER	INT DEFAULT 163;
    DECLARE CONST_CATEGORYID_ROBOTOCRD	INT DEFAULT 165;    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotImperva;    
	CREATE TEMPORARY TABLE Temp_RobotImperva(	  
			LogID		BIGINT
	);	
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotDetection;    
	CREATE TEMPORARY TABLE Temp_RobotDetection(
			ID					BIGINT UNSIGNED 
		,	CustID				BIGINT UNSIGNED  
        ,	CategoryID			SMALLINT UNSIGNED NOT NULL
        ,	LastModifiedDate	DATETIME(3)
        ,	PRIMARY KEY PK_Temp_RobotDetection_ID(ID)
        ,	INDEX IX_Temp_RobotDetection_CustIDCategoryID(CustID,CategoryID)
	);
    
    INSERT INTO Temp_RobotDetection(ID, CustID, CategoryID, LastModifiedDate)
    SELECT	rd.ID
		,	rd.CustID
		, 	(CASE WHEN rd.PeriodRangeType = 200 THEN CONST_CATEGORYID_ROBOTOCRD 
				ELSE CONST_CATEGORYID_ROBOTUSER END) AS CategoryID
		,	rd.LastModifiedDate
    FROM CTS_DataCenter.RobotDetection AS rd
    WHERE rd.ID > ip_RobotDetectionLastID
		AND rd.IsDisabled = 0
    ORDER BY rd.ID ASC
    LIMIT CONST_BATCHSIZE;    

	SELECT	tmpRd.CustID
		,	tmpRd.CategoryID
        ,	MAX(tmpRd.ID) AS RobotDetectionID
        , 	MAX(tmpRd.LastModifiedDate) AS LastModifiedDate
    FROM Temp_RobotDetection AS tmpRd
    GROUP BY tmpRd.CustID, tmpRd.CategoryID;

	SELECT ri.LogID AS RobotImpervaLogID, ri.CustID, ri.CreateTime AS LastCreateTime
	FROM CTS_DataCenter.RobotImperva AS ri
    WHERE ri.LogID > ip_RobotImpervaLastLogID		
	ORDER BY ri.LogID ASC
	LIMIT CONST_BATCHSIZE;    

END$$	
DELIMITER ;
