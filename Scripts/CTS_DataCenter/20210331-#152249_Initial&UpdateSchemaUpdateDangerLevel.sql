/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210331@Irena.Vo
	Task: Initial & Update Schema for Update Dangerous Level
	DB: CTS_DataCenter
*/

USE CTS_DataCenter;

/* 1. Initial Subscriber Group for Subscriber is NULL => Licensee */
UPDATE CTS_DataCenter.MappingSubscriberSite
SET SubscriberGroupID = 2
WHERE SubscriberGroupID IS NULL;

/* 2. Initial danger level type */
INSERT INTO CTS_DataCenter.StaticList
(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES
(10,1, 'Danger Level Type','Danger Level Type','Original','Original',1,1,'Original',CURRENT_TIME()),
(10,2, 'Danger Level Type','Danger Level Type','ABI','ABI',2,1,'ABI',CURRENT_TIME()),
(10,3, 'Danger Level Type','Danger Level Type','Other Sports','Other Sports',3,1,'Other Sports',CURRENT_TIME());

/* 3. Create Schema & Initial Mapping Danger Level */
DROP TABLE IF EXISTS `CTS_DataCenter`.`CategoryToDangerLevel`;
CREATE TABLE IF NOT EXISTS `CTS_DataCenter`.`CategoryToDangerLevel` (
		`CategoryID` 	SMALLINT UNSIGNED
 	,	`IsLicensee` 	BIT DEFAULT 0 -- 0: Credit/CN88, 1: Licensee
    ,	`TypeID`		SMALLINT -- 1: Original, 2: ABI, 3: Other Sports
    ,	`DangerLevel`	SMALLINT
    ,	PRIMARY KEY PK_CategoryToDangerLevel (CategoryID,IsLicensee,TypeID)
) ENGINE=INNODB;

-- Credit/ CN88
INSERT INTO CTS_DataCenter.CategoryToDangerLevel
(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES
(211,0,1,1),(221,0,1,1),(231,0,1,1),(251,0,1,1),(261,0,1,1),(271,0,1,1),
(212,0,1,2),(222,0,1,2),(232,0,1,2),(252,0,1,2),(262,0,1,2),(272,0,1,2),
(213,0,1,3),(223,0,1,3),(233,0,1,3),(253,0,1,3),(263,0,1,3),(273,0,1,3);

-- Licensee
INSERT INTO CTS_DataCenter.CategoryToDangerLevel
(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES
(211,1,1,11),(221,1,1,11),(231,1,1,11),(251,1,1,11),(261,1,1,11),(271,1,1,11),
(212,1,1,12),(222,1,1,12),(232,1,1,12),(252,1,1,12),(262,1,1,12),(272,1,1,12),
(213,1,1,13),(223,1,1,13),(233,1,1,13),(253,1,1,13),(263,1,1,13),(273,1,1,13);

/* 4. Initial Log */
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN TargetDangerLevel1 SMALLINT, -- Original
ADD COLUMN IsAppliedDangerLevel1 BIT DEFAULT b'0'; -- Original