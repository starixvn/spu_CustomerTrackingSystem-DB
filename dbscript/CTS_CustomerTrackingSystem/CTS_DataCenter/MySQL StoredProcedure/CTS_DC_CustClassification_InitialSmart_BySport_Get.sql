/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_InitialSmart_BySport_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InitialSmart_BySport_Get`(
        IN 	ip_BatchSize            SMALLINT
    ,   OUT op_NextScannedDateTime  DATETIME(3)
	,   OUT op_NextScannedCustID    BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250908@Logan.Nguyen
		Task:	 	Get cust to classify 2900/2901
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250908@Logan.Nguyen: Created [Redmine ID: #237405]
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_BySport_Get(@BatchSize,@NextScannedDateTime,@NextScannedCustID);
            SELECT @NextScannedDateTime,@NextScannedCustID
	*/
    DECLARE  CONST_CATEID_INITIALSMART	INT;
    
	DECLARE lv_LastScannedDate      DATETIME(3);
	DECLARE lv_LastScannedCustID    BIGINT UNSIGNED;
    DECLARE lv_SecondBatchSize      SMALLINT;
    DECLARE lv_TotalRow             SMALLINT;
	
    SET CONST_CATEID_INITIALSMART   = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMART');

    SELECT sys.ParameterValue
    INTO lv_LastScannedCustID
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE sys.ParameterID = 196;

    SELECT sys.ParameterValue
    INTO lv_LastScannedDate
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE sys.ParameterID = 197;

    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			CustID				BIGINT UNSIGNED
        ,   SportType           INT
		,	Probability		    DECIMAL(8,4)
        ,   SourceCreatedDate 	DATETIME(3)
        ,   InsertedTime        DATETIME(3)
        ,   PRIMARY KEY (InsertedTime, CustID)
    );
    
    INSERT INTO Temp_Customer(CustID, SportType, Probability, SourceCreatedDate, InsertedTime)
    SELECT	cs.CustID
        ,   cs.SportType
		, 	cs.Probability
        ,	cs.SourceCreatedDate
		,	cs.InsertedTime
    FROM CTS_DataCenter.Customer_InitialSmart_BySport AS cs
        INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON cs.SportType = ccs.SportType
    WHERE cs.InsertedTime = lv_LastScannedDate
		AND cs.CustID > lv_LastScannedCustID
	ORDER BY cs.InsertedTime ASC, cs.CustID ASC
	LIMIT ip_BatchSize;
    
    SET lv_TotalRow = (SELECT COUNT(1) FROM Temp_Customer);
    
    IF lv_TotalRow < ip_BatchSize THEN   
        SET lv_SecondBatchSize = ip_BatchSize - lv_TotalRow;
        
        INSERT INTO Temp_Customer(CustID, SportType, Probability, SourceCreatedDate, InsertedTime)
		SELECT	cs.CustID
            ,   cs.SportType
            , 	cs.Probability
            ,	cs.SourceCreatedDate
            ,	cs.InsertedTime
		FROM CTS_DataCenter.Customer_InitialSmart_BySport AS cs
            INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON cs.SportType = ccs.SportType
		WHERE cs.InsertedTime > lv_LastScannedDate
		ORDER BY cs.InsertedTime ASC, cs.CustID ASC
		LIMIT lv_SecondBatchSize;
    END IF;
    
    SET op_NextScannedDateTime = IFNULL((SELECT MAX(InsertedTime) FROM Temp_Customer), lv_LastScannedDate);
    SET op_NextScannedCustID = IFNULL((SELECT MAX(CustID) FROM Temp_Customer WHERE InsertedTime = op_NextScannedDateTime), lv_LastScannedCustID);

    SELECT	tmp.CustID
        ,	cus.CTSCustID
        ,	cus.SubscriberID
        ,	cus.RoleID
        ,   cus.IsLicensee
        ,	CONST_CATEID_INITIALSMART   AS CategoryID
        ,	CONST_CATEID_INITIALSMART   AS CategoryGroup
        ,   tmp.Probability
        ,   tmp.SourceCreatedDate       AS DetectedDate
	FROM Temp_Customer AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CustID = cus.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
    
END$$	
DELIMITER ;
