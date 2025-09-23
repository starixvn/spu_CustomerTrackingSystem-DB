/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250922@Logan.Nguyen
Task:	 	Adjust CC2700_2701
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250922@Logan.Nguyen: Created [Redmine ID: #239118]
Reviewer:
*/



/*******************************INIT Table CustomerCategorySettings*********************************/

USE CTS_DataCenter;

UPDATE CTS_DataCenter.CustomerCategorySettings AS ccs
JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID
SET SportType = 1
WHERE cc.CategoryID in (30200, 35200);


/*******************************Migrate Table Customer_InitialSmart_BySport and Customer_InitialSmart_BySport_Log*********************************/

USE CTS_DataCenter;

/* Migrate Customer_InitialSmart -> Customer_InitialSmart_BySport */
INSERT INTO CTS_DataCenter.Customer_InitialSmart_BySport (
        CustID
    ,   SportType
    ,   Probability
    ,   SourceCreatedDate
    ,   InsertedTime
)
SELECT  src.CustID
    ,   1 AS SportType
    ,   src.Probability
    ,   src.SourceCreatedDate
    ,   src.InsertedTime
FROM CTS_DataCenter.Customer_InitialSmart AS src;


/* Migrate Customer_InitialSmart_Log -> Customer_InitialSmart_BySport_Log */
INSERT INTO CTS_DataCenter.Customer_InitialSmart_BySport_Log (
        CustID
    ,   SportType
    ,   Probability
    ,   SourceCreatedDate
    ,   InsertedTime
)
SELECT  src.CustID
    ,   1 AS SportType
    ,   src.Probability
    ,   src.SourceCreatedDate
    ,   src.InsertedTime
FROM CTS_DataCenter.Customer_InitialSmart_Log AS src;


/*******************************update Sys Param*********************************/

USE CTS_DataCenter;

START TRANSACTION;

SET @lv_LastScanCustID      := (SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 159);
SET @lv_LastScanDate        := (SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 160);
SET @lv_B_LastScanCustID    := (SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 196);
SET @lv_B_LastScanDate      := (SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 197);

UPDATE SystemParameter
   SET ParameterValue = @lv_LastScanCustID
 WHERE ParameterID = 196
   AND @lv_LastScanCustID IS NOT NULL
   AND @lv_B_LastScanCustID IS NOT NULL
   AND @lv_LastScanCustID < @lv_B_LastScanCustID;

UPDATE SystemParameter
   SET ParameterValue = @lv_LastScanDate
 WHERE ParameterID = 197
   AND @lv_LastScanDate IS NOT NULL
   AND @lv_B_LastScanDate IS NOT NULL
   AND @lv_LastScanDate < @lv_B_LastScanDate;

COMMIT;





/*******************************Remove SP CTS_DC_CustClassification_InitialSmart_Get*********************************/

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DEL_CTS_DC_CustClassification_InitialSmart_Get`(
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
                - 20240628@Thomas.Nguyen: Renovate CC phase 2 - Remove hardcode CategoryID [Redmine ID: #205317]

		Example:
			CALL CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_Get(@NextScannedDateTime,@NextScannedCustID);
            SELECT @NextScannedDateTime,@NextScannedCustID
	*/
    DECLARE  CONST_CATEID_INITIALSMART	INT;
    
	DECLARE lv_LastScannedDate DATETIME(3);
	DECLARE lv_LastScannedCustID BIGINT UNSIGNED;
    DECLARE lv_BatchSize SMALLINT;
    DECLARE lv_SecondBatchSize SMALLINT;
    DECLARE lv_TotalRow SMALLINT;
	
    SET CONST_CATEID_INITIALSMART 		            = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMART');

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
			CustID				BIGINT UNSIGNED
		,	Probability		    DECIMAL(8,2)
        ,   SourceCreatedDate 	DATETIME(3)
        ,   InsertedTime        DATETIME(3)
        ,   PRIMARY KEY (InsertedTime, CustID)
    );
    
    INSERT INTO Temp_Customer(CustID, Probability, SourceCreatedDate, InsertedTime)
    SELECT	cs.CustID
		, 	cs.Probability
        ,	cs.SourceCreatedDate
		,	cs.InsertedTime
    FROM CTS_DataCenter.Customer_InitialSmart AS cs
    WHERE cs.InsertedTime = lv_LastScannedDate
		AND cs.CustID > lv_LastScannedCustID
	ORDER BY cs.InsertedTime ASC, cs.CustID ASC
	LIMIT lv_BatchSize;
    
    SET lv_TotalRow = (SELECT COUNT(1) FROM Temp_Customer);
    
    IF lv_TotalRow < lv_BatchSize THEN   
        SET lv_SecondBatchSize = lv_BatchSize - lv_TotalRow;
        
        INSERT INTO Temp_Customer(CustID, Probability, SourceCreatedDate, InsertedTime)
		SELECT	cs.CustID
            , 	cs.Probability
            ,	cs.SourceCreatedDate
            ,	cs.InsertedTime
		FROM CTS_DataCenter.Customer_InitialSmart AS cs
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
        ,	CONST_CATEID_INITIALSMART AS CategoryID
        ,	CONST_CATEID_INITIALSMART AS CategoryGroup
        ,   tmp.Probability
        ,   tmp.SourceCreatedDate AS DetectedDate
	FROM Temp_Customer AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmp.CustID = cus.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
    
END


DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_Get;



