/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230310@Victoria.le: 	STEP 2: MappingSubscriberSite - Add new sites and update value for column SiteLabel [Redmine ID: #183140]

*/
SET @SiteList = '[{"SiteID":23,"SiteName":"222223","SiteLabel":"Nova88"},{"SiteID":16,"SiteName":"611111","SiteLabel":"Nova88"},{"SiteID":20,"SiteName":"722222","SiteLabel":"Nova88"},{"SiteID":21,"SiteName":"733333","SiteLabel":"Nova88"},{"SiteID":22,"SiteName":"755555","SiteLabel":"Nova88"},{"SiteID":547,"SiteName":"76666B","SiteLabel":"IBC"},{"SiteID":188,"SiteName":"7aa666","SiteLabel":"Nova88"},{"SiteID":1,"SiteName":"BEST-ODDS","SiteLabel":"Nova88"},{"SiteID":487,"SiteName":"IBCIndo","SiteLabel":"IBC"},{"SiteID":147,"SiteName":"IMBC","SiteLabel":"Nova88"},{"SiteID":11,"SiteName":"INDO","SiteLabel":"Nova88"},{"SiteID":109,"SiteName":"JPNIBC","SiteLabel":"Nova88"},{"SiteID":35,"SiteName":"KORIBC","SiteLabel":"Nova88"},{"SiteID":13,"SiteName":"XYZBET","SiteLabel":"Nova88"},{"SiteID":1041,"SiteName":"y789","SiteLabel":"789y"},{"SiteID":1042,"SiteName":"y889","SiteLabel":"789y"},{"SiteID":1043,"SiteName":"yOther","SiteLabel":"789y"},{"SiteID":1040,"SiteName":"yUT","SiteLabel":"789y"}]';

DROP TEMPORARY TABLE IF EXISTS Temp_Sites;
CREATE TEMPORARY TABLE Temp_Sites(
		SiteID			INT
	,	SiteName		VARCHAR(50)
    ,	SiteLabel		VARCHAR(50)
    
    ,	PRIMARY KEY PK_Temp_Sites (SiteID)
);

DROP TEMPORARY TABLE IF EXISTS Temp_MappingSubscriberSite;
CREATE TEMPORARY TABLE Temp_MappingSubscriberSite(
		SubscriberID		INT
	,	SubscriberName		VARCHAR(50)
    ,	RoleMapping			TINYINT
    ,	SubscriberType		TINYINT
    ,	SubscriberStatus	TINYINT
    ,	SubscriberGroupID	SMALLINT
    ,	SiteID				INT
    ,	SiteName			VARCHAR(50)
    ,	Comments			VARCHAR(200)
	,	SiteLabel			VARCHAR(50)
);				
                
INSERT IGNORE INTO Temp_Sites (SiteID, SiteName, SiteLabel)
SELECT 	js.SiteID
	,	js.SiteName
    ,	js.SiteLabel
FROM JSON_TABLE(@SiteList,
				"$[*]" COLUMNS(
									SiteID		INT 			PATH "$.SiteID" 	
								,	SiteName	VARCHAR(50)  	PATH "$.SiteName"  
                                ,	SiteLabel	VARCHAR(50)  	PATH "$.SiteLabel"  
								)
				) AS js; 
				
INSERT INTO Temp_MappingSubscriberSite (SubscriberID,SubscriberName,RoleMapping,SubscriberType,SubscriberStatus
										,SubscriberGroupID,SiteID,SiteName,Comments,SiteLabel)
SELECT	m.SubscriberID,m.SubscriberName,m.RoleMapping,m.SubscriberType,m.SubscriberStatus
		,m.SubscriberGroupID,s.SiteID,s.SiteName,m.Comments,s.SiteLabel
FROM Temp_Sites AS s
	CROSS JOIN MappingSubscriberSite AS m 
WHERE s.SiteLabel = '789y'
	AND m.SiteID = 3;
	
INSERT INTO MappingSubscriberSite (SubscriberID,SubscriberName,RoleMapping,SubscriberType,SubscriberStatus
									,SubscriberGroupID,SiteID,SiteName,Comments,SiteLabel)
SELECT SubscriberID,SubscriberName,RoleMapping,SubscriberType,SubscriberStatus
		,SubscriberGroupID,SiteID,SiteName,Comments,SiteLabel
FROM Temp_MappingSubscriberSite;

UPDATE MappingSubscriberSite AS m
	INNER JOIN Temp_Sites as s ON s.SiteID = m.SiteID
SET m.SiteLabel = s.SiteLabel
WHERE s.SiteLabel <> '789y';