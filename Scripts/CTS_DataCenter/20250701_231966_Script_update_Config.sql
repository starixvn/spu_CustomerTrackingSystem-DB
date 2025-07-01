/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250701@Logan.Nguyen
Task:	 	add column config and init config
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250701@Logan.Nguyen: Created [Redmine ID: #229875]

Reviewer:
*/

-- AC02 --------------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsSpecialLicenseeClass TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsSpecialLicenseeClass = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE
        CustomerClassName LIKE '%Suspicious%'
     OR CustomerClassName LIKE '%Danger%'
     OR CustomerClassName LIKE '%Problem%'
     OR CustomerClassName LIKE '%Robot%'
);

SELECT * FROM CustomerCategorySettings WHERE IsSpecialLicenseeClass = 1;

-- AC03 ----------------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsIndoSpecialClass TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsIndoSpecialClass = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE CustomerClass IN (
        203, 2303, 2005, 2105, 2205, 2305,
        2600, 2700, 2800, 204, 205, 2304,
        301, 3101, 302, 303, 304, 300, 2100, 2300
    )
);

SELECT * FROM CustomerCategorySettings WHERE IsIndoSpecialClass = 1;

-- AC04 --------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsGoodOrNormalClass TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsGoodOrNormalClass = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE CategoryName LIKE '%Good%'
       OR CategoryName LIKE '%Normal%'
);

SELECT * FROM CustomerCategorySettings WHERE IsGoodOrNormalClass = 1;

