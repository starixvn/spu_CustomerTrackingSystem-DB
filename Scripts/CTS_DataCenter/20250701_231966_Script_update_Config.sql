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

-- AC01 --------------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsOri18Excepted TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsOri18Excepted = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE CustomerClass in (200)
);

-- SELECT * FROM CustomerCategorySettings WHERE IsOri18Excepted = 1;
-- AC02 --------------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsOri19TargetClass TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsOri19TargetClass = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE
        CustomerClassName LIKE '%Suspicious%'
     OR CustomerClassName LIKE '%Dangerous%'
     OR CustomerClassName LIKE '%Problem%'
     OR CustomerClassName LIKE '%Robot%'
);

-- SELECT * FROM CustomerCategorySettings WHERE IsOri19TargetClass = 1;

-- AC03 ----------------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsOri17TargetClass TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsOri17TargetClass = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE CustomerClass IN (
        203, 2303, 2005, 2105, 2205, 2305,
        2600, 2700, 2800, 204, 205, 2304,
        301, 3101, 302, 303, 304, 300, 2100, 2300
    )
);

-- SELECT * FROM CustomerCategorySettings WHERE IsOri17TargetClass = 1;

-- AC04 --------------------------------------------------

ALTER TABLE CustomerCategorySettings
ADD COLUMN IsOri0ResetClass TINYINT(1) DEFAULT 0;

UPDATE CustomerCategorySettings
SET IsOri0ResetClass = 1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM CustomerCategory
    WHERE CustomerClass in (201,202)
);

-- SELECT * FROM CustomerCategorySettings WHERE IsOri0ResetClass = 1;

