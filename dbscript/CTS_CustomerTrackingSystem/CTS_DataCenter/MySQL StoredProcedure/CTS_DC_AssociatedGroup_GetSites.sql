/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_GetSites`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_GetSites`(
		IN ip_GroupID 			BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
/* 
		Created:	20220831@Aries.Nguyen
		Task :		[CTS] Associated Group Enhancement
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220831@Aries.Nguyen: Created [Redmine ID: #176991] 
		
        Param's Explanation: 

		Example:
			- CALL CTS_DC_AssociatedGroup_GetSites(1);

*/	
	DECLARE lv_AllCredit		SMALLINT;
	DECLARE lv_AllLicensee		SMALLINT;
    DECLARE lv_Sites			LONGTEXT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupSite;
	CREATE TEMPORARY TABLE 		Temp_GroupSite (
			SiteID 		BIGINT UNSIGNED PRIMARY KEY
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Site;
	CREATE TEMPORARY TABLE 		Temp_Site (
			 SiteID 			BIGINT UNSIGNED PRIMARY KEY
        ,    SiteName 			VARCHAR(50)
        ,    IsLicensee			SMALLINT
        ,	 IsChosen			SMALLINT DEFAULT 0
	);
    
    SELECT 	AllCredit
        ,	AllLicensee
        ,	Sites
    INTO 	lv_AllCredit
        ,	lv_AllLicensee
        ,	lv_Sites
	FROM  CTS_DataCenter.AssociatedGroup
    WHERE GroupID = ip_GroupID
	LIMIT 1;
    
    IF lv_Sites IS NOT NULL AND lv_Sites != "" THEN
		SET @sql= CONCAT("INSERT IGNORE INTO Temp_GroupSite (SiteID) VALUES ('", REPLACE(lv_Sites, ',', "'),('"),"');");
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;
	END IF;
    
	
    
    INSERT IGNORE INTO Temp_Site(SiteID,SiteName,IsLicensee)
	SELECT 	SiteID
		,	SiteName
		,	CASE WHEN MAX(SubscriberGroupID) = 2 THEN 1 
			ELSE 0 END AS IsLicensee
	FROM CTS_DataCenter.MappingSubscriberSite
	GROUP BY SiteID
		,	 SiteName;
        
	UPDATE Temp_Site AS site
    SET IsChosen = 1
    WHERE (IsLicensee = 0 AND lv_AllCredit = 1) 
		OR (IsLicensee = 1 AND lv_AllLicensee = 1)
        OR EXISTS (SELECT 1 FROM Temp_GroupSite AS tmp WHERE site.SiteID = tmp.SiteID);
	
    SELECT 	SiteID 			
        ,   SiteName 			
        ,   IsLicensee		
        ,	IsChosen	
    FROM Temp_Site;
END$$
DELIMITER ;