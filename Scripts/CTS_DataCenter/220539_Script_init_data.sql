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


SELECT cls.CustID
FROM CTS_DataCenter.CTSCustomerClassification AS cls  
JOIN CTS_DataCenter.CTSCustomer AS cus
ON cls.CustID = cus.CustID
WHERE CategoryID IN (40500, 40600, 40701, 10200) 
AND cus.IsLicenseeVIP = 1
AND cls.CustID NOT IN (SELECT sub_cls.CustID  
                        FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls  
                        WHERE sub_cls.ParentID = 20000)
GROUP BY cls.CustID
HAVING COUNT(DISTINCT ParentID) > 1;


/*Create table save data*/
DROP TABLE IF EXISTS Adhoc_CC400_CC400_CustomerClassification_BeforeRelease;
DROP TABLE IF EXISTS Adhoc_CC400_CC400_CustomerClassification_InRelease;

CREATE TABLE Adhoc_CC400_CC400_CustomerClassification_BeforeRelease (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CustID INT NOT NULL,
    InsertedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Adhoc_CC400_CC400_CustomerClassification_InRelease (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CustID INT NOT NULL,
    InsertedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

/*run now for get data noti to S&V*/
INSERT INTO Adhoc_CC400_CC400_CustomerClassification_BeforeRelease (CustID)
SELECT cls.CustID
	FROM CTS_DataCenter.CTSCustomerClassification AS cls  
	JOIN CTS_DataCenter.CTSCustomer AS cus
	ON cls.CustID = cus.CustID
	WHERE CategoryID IN (40500, 40600, 40701, 10200) 
	AND cus.IsLicenseeVIP = 1
	AND cls.CustID NOT IN (SELECT sub_cls.CustID  
                        FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls  
                        WHERE sub_cls.ParentID = 20000)
	GROUP BY cls.CustID
	HAVING COUNT(DISTINCT ParentID) > 1;

SELECT * FROM Adhoc_CC400_CC400_CustomerClassification_BeforeRelease;

/*run before release*/
INSERT INTO Adhoc_CC400_CC400_CustomerClassification_InRelease (CustID)
SELECT cls.CustID
	FROM CTS_DataCenter.CTSCustomerClassification AS cls  
	JOIN CTS_DataCenter.CTSCustomer AS cus
	ON cls.CustID = cus.CustID
	WHERE CategoryID IN (40500, 40600, 40701, 10200) 
	AND cus.IsLicenseeVIP = 1
	AND cls.CustID NOT IN (SELECT sub_cls.CustID  
                        FROM CTS_DataCenter.CTSCustomerClassification AS sub_cls  
                        WHERE sub_cls.ParentID = 20000)
	GROUP BY cls.CustID
	HAVING COUNT(DISTINCT ParentID) > 1;

SELECT * FROM Adhoc_CC400_CC400_CustomerClassification_InRelease;

/*Release UPDATE*/

/*List cust before release and inrelease*/
SELECT CustID, InsertedDate
FROM Adhoc_CC400_CC400_CustomerClassification_BeforeRelease
UNION 
SELECT CustID, InsertedDate
FROM Adhoc_CC400_CC400_CustomerClassification_InRelease
ORDER BY CustID, InsertedDate;

/*info CustomerClassification after release*/
SELECT * 
	FROM CTS_DataCenter.CTSCustomerClassification AS cls  
	JOIN CTS_DataCenter.CTSCustomer AS cus
	ON cls.CustID = cus.CustID
WHERE cls.CustID IN (SELECT CustID
						FROM Adhoc_CC400_CC400_CustomerClassification_BeforeRelease
						UNION 
						SELECT CustID
						FROM Adhoc_CC400_CC400_CustomerClassification_InRelease
					);


