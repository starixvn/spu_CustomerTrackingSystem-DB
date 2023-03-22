/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230310@Victoria.le: 	STEP 4: CTSCustomer - Update SiteID and Site [Redmine ID: #183140]

*/
SET @CustListInfo = '';

DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
CREATE TEMPORARY TABLE Temp_CTSCustomer(
		CustID			BIGINT
	,	SiteName		VARCHAR(50)
    ,	SiteID			INT
    
    ,	PRIMARY KEY PK_Temp_Sites (CustID)
);
                
INSERT IGNORE INTO Temp_CTSCustomer (CustID, SiteName, SiteID)
SELECT 	js.CustID
	,	js.SiteName
    ,	CASE 	WHEN js.SiteName = 'yUT' 	THEN 1045
				WHEN js.SiteName = 'y789' 	THEN 1046
                WHEN js.SiteName = 'y889' 	THEN 1047
                WHEN js.SiteName = 'yOther' THEN 1048
		END
FROM JSON_TABLE(@CustListInfo,
				"$[*]" COLUMNS(
									CustID		INT 			PATH "$.CustID" 	
								,	SiteName	VARCHAR(50)  	PATH "$.SiteName"   
								)
				) AS js; 
                
UPDATE CTS_DataCenter.CTSCustomer AS c
	INNER JOIN Temp_CTSCustomer AS tmp ON tmp.CustID = c.CustID
SET 	c.SiteID = tmp.SiteID
	,	c.Site = tmp.SiteName
;