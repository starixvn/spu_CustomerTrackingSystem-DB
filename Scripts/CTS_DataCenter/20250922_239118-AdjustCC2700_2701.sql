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

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_Get;



