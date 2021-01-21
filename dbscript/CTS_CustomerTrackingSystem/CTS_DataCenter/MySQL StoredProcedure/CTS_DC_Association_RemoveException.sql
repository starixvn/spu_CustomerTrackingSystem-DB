/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_RemoveException`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_RemoveException`(IN ip_UserID int,IN ip_FromCTSCustID bigint,IN ip_ToCTSCustID bigint)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Remove Exception
		DB:			CTS_DataCenter
		Original: 
		
		Revisions:
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			
		Param's Explanation (filtered by):
	*/ 
	DECLARE		vr_LeastCTSCustID 	BIGINT;
    DECLARE		vr_GreatestCTSCustID 		BIGINT;
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_Association_RemoveException';
    
    SET	vr_CreatedDate = CURRENT_TIME();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
    CREATE TEMPORARY TABLE Temp_CustDevice
    (	CTSCustID		BIGINT
		, DCSDeviceID	BIGINT
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE Temp_CustAssociation
    (	FromCTSCustID		BIGINT
		, ToCTSCustID		BIGINT
	);
    
    SET vr_LeastCTSCustID = LEAST(ip_FromCTSCustID,ip_ToCTSCustID);
    SET	vr_GreatestCTSCustID = GREATEST(ip_FromCTSCustID,ip_ToCTSCustID);  

    #===Remove Exception
    DELETE	ce
    FROM	CTS_DataCenter.CustException AS ce
    WHERE	ce.LeastCTSCustID_Order 		= vr_LeastCTSCustID
			AND ce.GreatestCTSCustID_Order	= vr_GreatestCTSCustID;
    
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(2,vr_SPName, CONCAT('Remove Exception: ip_FromCTSCustID_', ip_FromCTSCustID, ';ip_ToCTSCustID', ip_ToCTSCustID), vr_CreatedDate, ip_UserID);
    
    #=====Insert Affected Evidence: GET Device And Association into Temp Table
    INSERT INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
    SELECT 		ad.CTSCustID
				, ad.DCSDeviceID
	FROM		CTS_DataCenter.AssociationByDevice AS ad
    WHERE		(ad.CTSCustID 	= ip_FromCTSCustID
				OR ad.CTSCustID = ip_ToCTSCustID);    
    
    # If exist any device association with The removed exception Customers
    IF EXISTS (SELECT 1 FROM Temp_CustDevice LIMIT 1) THEN
    
		INSERT	INTO Temp_CustAssociation(FromCTSCustID, ToCTSCustID)
		SELECT  	DISTINCT tcd.CTSCustID
					, ad.CTSCustID
		FROM		Temp_CustDevice 		AS tcd
		INNER JOIN	CTS_DataCenter.AssociationByDevice 	AS ad
					ON	tcd.DCSDeviceID			= ad.DCSDeviceID
		WHERE		ad.CTSCustID IN (ip_FromCTSCustID,ip_ToCTSCustID);
		
		DELETE	tca
		FROM	Temp_CustAssociation AS tca
		WHERE	tca.FromCTSCustID = tca.ToCTSCustID;
		
		# If ip_FromCTSCustID Association with ip_ToCTSCustID
		IF EXISTS (SELECT 1 FROM Temp_CustAssociation LIMIT 1) THEN 
        
			#=====Insert Affected Evidence: GET Device And Association into Temp Table         
            
			INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
			SELECT	tca.ToCTSCustID
					, EvidenceID
					, 'Auto RemoveException' AS Remark	# Auto by RemoveException
					, 2 				AS Level
					, ip_FromCTSCustID	AS FromCustID
					, vr_CreatedDate	AS CreatedDate
					, ce.CreatedBy 		AS CreatedBy
			FROM		CTS_DataCenter.CustEvidence	AS ce
			INNER JOIN	Temp_CustAssociation AS tca
						ON ce.CTSCustID = tca.FromCTSCustID
			WHERE		ce.CTSCustID	= ip_FromCTSCustID
						AND ce.Level	= 0;	
			
			INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
			SELECT	ip_FromCTSCustID
					, EvidenceID
					, 'Auto RemoveException' AS Remark
					, 2 				AS Level
					, ip_ToCTSCustID	AS FromCustID
					, vr_CreatedDate	AS CreatedDate
					, ce.CreatedBy 		AS CreatedBy
			FROM		CTS_DataCenter.CustEvidence	AS ce
			INNER JOIN	Temp_CustAssociation AS tca
						ON ce.CTSCustID = tca.FromCTSCustID
			WHERE		ce.CTSCustID	= ip_ToCTSCustID			
						AND ce.Level = 0;
			
			INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
			VALUES(3, vr_SPName, CONCAT('Auto Add by Remove Exception Function: ip_FromCTSCustID_ ', ip_FromCTSCustID, ';ip_ToCTSCustID', ip_ToCTSCustID) , vr_CreatedDate, ip_UserID);
			
        END IF;
	END IF;

END$$

DELIMITER ;