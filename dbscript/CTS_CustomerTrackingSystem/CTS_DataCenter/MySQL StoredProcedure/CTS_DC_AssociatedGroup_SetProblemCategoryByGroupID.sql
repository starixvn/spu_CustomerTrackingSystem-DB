/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID`(
		IN ip_GroupID 			BIGINT UNSIGNED
    ,	IN ip_PACategoryID		INT
    ,	IN ip_PACreditSites		TEXT
    ,	IN ip_PALicenseeSites	TEXT
    ,	IN ip_ModifiedBy 		INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
/* 
		Created:	20221025@Harvey.Nguyen
		Task :		[CTS] Associated Group Enhancement
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
            - 20221025@Harvey.Nguyen: Update PA for group [Redmine ID: #179398]
		
        Param's Explanation: 

		Example:
			- CALL CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID(@ip_GroupID:=1, @ip_PACategoryID:=52, @ip_PACreditSites:='1,2,3', @ip_PALicenseeSites:='4,5,6',8 );

*/    #Error Code: 1327. Undeclared variable: lv_NewPALicenseeSites

	DECLARE lv_AuditInfo JSON;
    DECLARE lv_PACreditSites TEXT;
    DECLARE lv_NewPACreditSites TEXT;
    DECLARE lv_PALicenseeSites TEXT;
    DECLARE lv_NewPALicenseeSites TEXT;
    
    SET lv_AuditInfo = JSON_OBJECT('CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID, GroupID', ip_GroupID, 
								   'PACategoryID', ip_PACategoryID, 
								   'PACreditSites', ip_PACreditSites, 
                                   'PALicenseeSites', ip_PALicenseeSites, 
                                   'ip_ModifiedBy', ip_ModifiedBy);
    
    INSERT INTO CTS_DataCenter.CTSAuditLog(EventName,CreatedBy, Info)
	VALUES("CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID",ip_ModifiedBy, lv_AuditInfo);
	
    IF ip_PACategoryID <> -1 THEN    
		UPDATE CTS_DataCenter.AssociatedGroup
		SET  	PACategoryID = ip_PACategoryID
			,	PACreditSites = ip_PACreditSites
			,	PALicenseeSites = ip_PALicenseeSites
			,	ModifiedBy = ip_ModifiedBy
		WHERE GroupID = ip_GroupID;
	ELSE
		#========Credit Sites=======================
		SELECT ag.PACreditSites 
		INTO lv_PACreditSites 
        FROM CTS_DataCenter.AssociatedGroup AS ag WHERE ag.GroupID = ip_GroupID; 		
        
		DROP TEMPORARY TABLE IF EXISTS Temp_PACreditSites;
		CREATE TEMPORARY TABLE Temp_PACreditSites(SiteID INT PRIMARY KEY);
        IF (lv_PACreditSites IS NOT NULL) THEN
			SET @sql = CONCAT("INSERT INTO Temp_PACreditSites (SiteID) VALUES ('", REPLACE(lv_PACreditSites, ",", "'),('"),"');");
			PREPARE stmt1 FROM @sql;
			EXECUTE stmt1;
        END IF;
        
		DROP TEMPORARY TABLE IF EXISTS Temp_RemovePACreditSites;
        CREATE TEMPORARY TABLE Temp_RemovePACreditSites(SiteID INT PRIMARY KEY);
        
        IF (ip_PACreditSites IS NOT NULL) THEN
			SET @sql = CONCAT("INSERT INTO Temp_RemovePACreditSites (SiteID) VALUES ('", REPLACE(ip_PACreditSites, ",", "'),('"),"');");        
			PREPARE stmt1 FROM @sql;
			EXECUTE stmt1;
        END IF;
	
		SELECT GROUP_CONCAT(tmpPs.SiteID)
        INTO lv_NewPACreditSites
        FROM Temp_PACreditSites AS tmpPs
			LEFT JOIN Temp_RemovePACreditSites AS tmpRev ON tmpPs.SiteID = tmpRev.SiteID
		WHERE tmpRev.SiteID IS NULL;
		
        UPDATE CTS_DataCenter.AssociatedGroup AS ag
		SET ag.PACreditSites = lv_NewPACreditSites
		WHERE ag.GroupID = ip_GroupID;
        
        #========Licensee Sites=======================
		SELECT ag.PALicenseeSites 
		INTO lv_PALicenseeSites 
        FROM CTS_DataCenter.AssociatedGroup AS ag WHERE ag.GroupID = ip_GroupID; 		
        
		DROP TEMPORARY TABLE IF EXISTS Temp_PALicenseeSites;
		CREATE TEMPORARY TABLE Temp_PALicenseeSites(SiteID INT PRIMARY KEY);
        IF (lv_PALicenseeSites IS NOT NULL) THEN
			SET @sql = CONCAT("INSERT INTO Temp_PALicenseeSites (SiteID) VALUES ('", REPLACE(lv_PALicenseeSites, ",", "'),('"),"');");
			PREPARE stmt1 FROM @sql;
			EXECUTE stmt1;
        END IF;
        
		DROP TEMPORARY TABLE IF EXISTS Temp_RemovePALicenseeSites;
        CREATE TEMPORARY TABLE Temp_RemovePALicenseeSites(SiteID INT PRIMARY KEY);
        
        IF (ip_PALicenseeSites IS NOT NULL) THEN
			SET @sql = CONCAT("INSERT INTO Temp_RemovePALicenseeSites (SiteID) VALUES ('", REPLACE(ip_PALicenseeSites, ",", "'),('"),"');");        
			PREPARE stmt1 FROM @sql;
			EXECUTE stmt1;
        END IF;
	
		SELECT GROUP_CONCAT(tmpPs.SiteID)
        INTO lv_NewPALicenseeSites
        FROM Temp_PALicenseeSites AS tmpPs
			LEFT JOIN Temp_RemovePALicenseeSites AS tmpRev ON tmpPs.SiteID = tmpRev.SiteID
		WHERE tmpRev.SiteID IS NULL;
		
        UPDATE CTS_DataCenter.AssociatedGroup AS ag
		SET ag.PALicenseeSites = lv_NewPALicenseeSites
		WHERE ag.GroupID = ip_GroupID;
        
        #==============================
        IF lv_NewPALicenseeSites IS NULL AND lv_NewPACreditSites IS NULL
        THEN
			UPDATE CTS_DataCenter.AssociatedGroup AS ag
			SET ag.PACategoryID = NULL
			WHERE ag.GroupID = ip_GroupID;
		END IF;
	END IF;
END$$
DELIMITER ;