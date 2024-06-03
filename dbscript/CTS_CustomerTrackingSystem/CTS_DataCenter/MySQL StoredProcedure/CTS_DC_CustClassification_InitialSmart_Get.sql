/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_InitialSmart_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InitialSmart_Get`(
        OUT op_NextScannedDateTime DATETIME(3)
	,   OUT op_NextScannedCustID BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20240530@Thomas.Nguyen
		Task:	 	Get cust to classify 2700/2701
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20240530@Thomas.Nguyen: Created [Redmine ID: #199345]
            
		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_Get(@NextScannedDateTime,@NextScannedCustID);
            SELECT @NextScannedDateTime,@NextScannedCustID
	*/
    DECLARE  CONST_CATEGORYID_INITIALSMART	INT DEFAULT 66;
    
	DECLARE lv_LastScannedDate DATETIME(3);
	DECLARE lv_LastScannedCustID BIGINT UNSIGNED;
    DECLARE lv_BatchSize SMALLINT;
    DECLARE lv_TotalRow SMALLINT;
	
    SELECT sys.ParameterValue
    INTO lv_LastScannedCustID
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE sys.ParameterID = 159;

    SELECT sys.ParameterValue
    INTO lv_LastScannedDate
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE sys.ParameterID = 160;
    
    SELECT sys.ParameterValue
    INTO lv_BatchSize
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE sys.ParameterID = 161;

    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			CustID				BIGINT UNSIGNED PRIMARY KEY
		,	Probability		    DECIMAL(8,4)
        ,   PredictTime 	    DATETIME(3)
        ,   InsertedTime        DATETIME(3)
    );
    
    INSERT INTO Temp_Customer(CustID, Probability, PredictTime, InsertedTime)
    SELECT	cs.CustID
		, 	cs.Probability
        ,	cs.PredictTime
		,	cs.InsertedTime
    FROM CTS_DataCenter.Customer_InitialSmart AS cs
    WHERE cs.InsertedTime = lv_LastScannedDate
		AND cs.CustID > lv_LastScannedCustID
	ORDER BY cs.InsertedTime ASC, cs.CustID ASC
	LIMIT lv_BatchSize;
    
    SET lv_TotalRow = (SELECT COUNT(1) FROM Temp_Customer);
    
    IF lv_TotalRow < lv_BatchSize THEN    
        INSERT INTO Temp_Customer(CustID, Probability, PredictTime, InsertedTime)
		SELECT	cs.CustID
            , 	cs.Probability
            ,	cs.PredictTime
            ,	cs.InsertedTime
		FROM CTS_DataCenter.Customer_InitialSmart AS cs
		WHERE cs.InsertedTime > lv_LastScannedDate
		ORDER BY cs.InsertedTime ASC, cs.CustID ASC
		LIMIT lv_BatchSize;
    END IF;
    
    SET op_NextScannedDateTime = IFNULL((SELECT MAX(InsertedTime) FROM Temp_Customer), lv_LastScannedDate);
    SET op_NextScannedCustID = IFNULL((SELECT MAX(CustID) FROM Temp_Customer WHERE InsertedTime = op_NextScannedDateTime), lv_LastScannedCustID);

    SELECT	tmp.CustID
        ,	cus.CTSCustID
        ,	cus.SubscriberID
        ,	cus.RoleID
        ,   cus.IsLicensee
        ,	CONST_CATEGORYID_INITIALSMART AS CategoryID
        ,	CONST_CATEGORYID_INITIALSMART AS CategoryGroup
        ,   tmp.Probability
        ,   tmp.PredictTime AS DetectedDate
	FROM Temp_Customer AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CustID = cus.CustID AND cus.CustSubID = 0;
    
END$$	
DELIMITER ;
