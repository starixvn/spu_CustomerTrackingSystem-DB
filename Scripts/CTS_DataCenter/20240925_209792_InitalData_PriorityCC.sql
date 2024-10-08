/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240923@Jonas.Huynh
Task:	 	script updata data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240923@Jonas.Huynh: Created  [RedmineID: #209792]
Reviewer:
*/
USE CTS_DataCenter;

SET @CONST_CATEID_EARLYWARNING			 = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNING');
SET @CONST_CATEID_EARLYWARNINGLOSING 	 = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNINGLOSING');
SET @CONST_CATEID_INITIALSMART 			 = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMART');
SET @CONST_CATEID_INITIALSMARTLOSING	 = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMARTLOSING');
SET @CONST_CATEID_INITIALGB				 = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGB');
SET @CONST_CATEID_INITIALGBLOSING		 = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGBLOSING');
SET @CONST_PARENTID_PA					 = CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
SET @CONST_PARENTID_POTENTIALPA			 = CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');

DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
CREATE TEMPORARY TABLE Temp_Customers(
		CustID		BIGINT UNSIGNED
	,   ParentID	INT NOT NULL
    ,   CategoryID 	INT NOT NULL   
    , 	PRIMARY KEY (CustID, CategoryID)
);

INSERT INTO Temp_Customers(CustID, ParentID, CategoryID)
SELECT DISTINCT CustID, ParentID, CategoryID
FROM CTS_DataCenter.CTSCustomerClassification AS cc
WHERE CategoryID IN (@CONST_CATEID_EARLYWARNING, @CONST_CATEID_EARLYWARNINGLOSING, @CONST_CATEID_INITIALSMART, @CONST_CATEID_INITIALSMARTLOSING, @CONST_CATEID_INITIALGB, @CONST_CATEID_INITIALGBLOSING)
	AND ParentID = @CONST_PARENTID_POTENTIALPA;

-- #1. Update Table CTSCustomerClassification
UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
	INNER JOIN Temp_Customers AS c ON c.CustID = cc.CustID 
		AND c.ParentID = cc.ParentID 
		AND c.CategoryID = cc.CategoryID
SET cc.ParentID = @CONST_PARENTID_PA;

-- #2. Update Table CTSCustomerClassification_History
UPDATE CTS_DataCenter.CTSCustomerClassification_History AS cc
	INNER JOIN Temp_Customers AS c ON c.CustID = cc.CustID 
		AND c.ParentID = cc.ParentID 
		AND c.CategoryID = cc.CategoryID
SET cc.ParentID = @CONST_PARENTID_PA;
    
-- #3. Update Table CTSCustomerClassification_Log
UPDATE CTS_DataCenter.CTSCustomerClassification_Log AS cc
	INNER JOIN Temp_Customers AS c ON c.CustID = cc.CustID 
		AND c.ParentID = cc.ParentID 
		AND c.CategoryID = cc.CategoryID
SET cc.ParentID = @CONST_PARENTID_PA;
 
 -- #4
UPDATE CTS_DataCenter.CTSCustomerClassification_History AS cc
SET cc.ParentID = @CONST_PARENTID_PA
WHERE cc.ParentID = @CONST_PARENTID_POTENTIALPA;

UPDATE CTS_DataCenter.CTSCustomerClassification_Log AS cc
SET cc.ParentID = @CONST_PARENTID_PA
WHERE cc.ParentID = @CONST_PARENTID_POTENTIALPA;

-- #5. Skip Table CTSCustomerClassification_History_Renovate_Archive
-- #6. Skip Table ArchiveCustomer_CTSCustomer (Count = 0)