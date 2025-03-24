/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250318@Logan.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250318@Logan.Nguyen: Created [Redmine ID: #220539]

Reviewer:
*/


/*script get data*/
-- Script report
SELECT 
    cus.CustID,
    cus.UserName,
    cus.CreatedDate,
    GROUP_CONCAT(DISTINCT cat.CategoryName ORDER BY cat.CategoryName SEPARATOR ', ') AS CurrentCategoryName,
    MAX(CASE WHEN cat.CustomerClass = 4000 THEN cat.CustomerClass ELSE NULL END) AS CurrentCC,
    MAX(cls.LastModifiedDate) AS CurrentCC_CreatedDate
FROM (
    SELECT cls.CustID
    FROM CTS_DataCenter.CTSCustomerClassification AS cls  
    JOIN CTS_DataCenter.CTSCustomer AS cus
        ON cls.CustID = cus.CustID
    WHERE cls.CategoryID IN (40500, 40600, 40701, 10200) 
        AND cus.IsLicenseeVIP = 1
        AND NOT EXISTS (
            SELECT 1
            FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls
            WHERE sub_cls.CustID = cls.CustID
              AND sub_cls.ParentID IN (1000, 20000)
        )
    GROUP BY cls.CustID
    HAVING COUNT(DISTINCT cls.ParentID) > 1
) AS filter_cus
JOIN CTS_DataCenter.CTSCustomer AS cus
    ON filter_cus.CustID = cus.CustID
JOIN CTS_DataCenter.CTSCustomerClassification AS cls
    ON cus.CustID = cls.CustID
JOIN CTS_DataCenter.CustomerCategory AS cat
    ON cls.CategoryID = cat.CategoryID
GROUP BY cus.CustID, cus.UserName, cus.CreatedDate;

-- Metaverse - file cvs
USE CTS_DataCenter;

SELECT cls.CustID
FROM CTS_DataCenter.CTSCustomerClassification AS cls  
JOIN CTS_DataCenter.CTSCustomer AS cus
  ON cls.CustID = cus.CustID
WHERE CategoryID IN (40500, 40600, 40701, 10200) 
  AND cus.IsLicenseeVIP = 1
  AND NOT EXISTS (
    SELECT 1
    FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls
    WHERE sub_cls.CustID = cls.CustID
      AND sub_cls.ParentID in (1000,20000)
)
GROUP BY cls.CustID
HAVING COUNT(DISTINCT ParentID) > 1;


/*Create table save data*/
DROP TABLE IF EXISTS Adhoc_217747_CustomerClassification_BeforeRelease;
DROP TABLE IF EXISTS Adhoc_217747_CustomerClassification_InRelease;

CREATE TABLE Adhoc_217747_CustomerClassification_BeforeRelease (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CustID INT NOT NULL,
    InsertedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Adhoc_217747_CustomerClassification_InRelease (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CustID INT NOT NULL,
    InsertedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

/*run now for get data noti to S&V*/
INSERT INTO Adhoc_217747_CustomerClassification_BeforeRelease (CustID)
SELECT cls.CustID
FROM CTS_DataCenter.CTSCustomerClassification AS cls  
JOIN CTS_DataCenter.CTSCustomer AS cus
  ON cls.CustID = cus.CustID
WHERE CategoryID IN (40500, 40600, 40701, 10200) 
  AND cus.IsLicenseeVIP = 1
  AND NOT EXISTS (
    SELECT 1
    FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls
    WHERE sub_cls.CustID = cls.CustID
      AND sub_cls.ParentID in (1000,20000)
)
GROUP BY cls.CustID
HAVING COUNT(DISTINCT ParentID) > 1;

SELECT * FROM Adhoc_217747_CustomerClassification_BeforeRelease;

/*run before release*/
INSERT INTO Adhoc_217747_CustomerClassification_InRelease (CustID)
SELECT cls.CustID
FROM CTS_DataCenter.CTSCustomerClassification AS cls  
JOIN CTS_DataCenter.CTSCustomer AS cus
  ON cls.CustID = cus.CustID
WHERE CategoryID IN (40500, 40600, 40701, 10200) 
  AND cus.IsLicenseeVIP = 1
  AND NOT EXISTS (
    SELECT 1
    FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls
    WHERE sub_cls.CustID = cls.CustID
      AND sub_cls.ParentID in (1000,20000)
)
GROUP BY cls.CustID
HAVING COUNT(DISTINCT ParentID) > 1;

SELECT * FROM Adhoc_217747_CustomerClassification_InRelease;

/*Release UPDATE*/

/*List cust before release and inrelease*/
SELECT CustID, InsertedDate
FROM Adhoc_217747_CustomerClassification_BeforeRelease
UNION 
SELECT CustID, InsertedDate
FROM Adhoc_217747_CustomerClassification_InRelease
ORDER BY CustID, InsertedDate;

/*info CustomerClassification after release*/
SELECT * 
	FROM CTS_DataCenter.CTSCustomerClassification AS cls  
	JOIN CTS_DataCenter.CTSCustomer AS cus
	ON cls.CustID = cus.CustID
WHERE cls.CustID IN (SELECT CustID
						FROM Adhoc_217747_CustomerClassification_BeforeRelease
						UNION 
						SELECT CustID
						FROM Adhoc_217747_CustomerClassification_InRelease
					);


