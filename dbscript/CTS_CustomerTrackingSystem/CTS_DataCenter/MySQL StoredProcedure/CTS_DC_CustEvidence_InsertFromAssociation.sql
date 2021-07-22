/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_InsertFromAssociation`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertFromAssociation`(
		IN ip_Batch INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Place Affected Evidence for New AssociationByDevice
		DB:			CTS_DataCenter
		Original:
		
		Revisions:	
			- 20200303@Casey.Huynh: Update Affected CreateBy = Root CreatedBy
			- 20200805@Casey.Huynh: Update Bussiness affect Crosssub and correct update value LastCTSAssDevID
			- 20200807@Casey.Huynh:[138925] Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster
			- 20200821@Casey.Huynh:[140100]: Return CustID is added affected evidence
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			- 20210510@Aries.Nguyen: Remove insert log zzTracePerformance [Redmine ID: #154792]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]

		Param's Explanation (filtered by):
	*/
    
    DECLARE	lv_LastCTSAssDevID BIGINT UNSIGNED;
    DECLARE	lv_CreatedDate	DATETIME;
  
    
    SET	lv_CreatedDate = CURRENT_TIME();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice;    
	CREATE TEMPORARY TABLE Temp_AssociationByDevice( 	
			CTSAssDevID		BIGINT	UNSIGNED
        ,	FromCTSCustID	BIGINT	UNSIGNED
        ,	DCSDeviceID	BIGINT	UNSIGNED
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;    
	CREATE TEMPORARY TABLE Temp_CustAssociation( 		
			FromCTSCustID		BIGINT	UNSIGNED
        ,	ToCTSCustID			BIGINT	UNSIGNED
	);	
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;    
	CREATE TEMPORARY TABLE Temp_CustEvidence(
			CTSCustID			BIGINT		UNSIGNED					NOT NULL
		,	EvidenceID			SMALLINT								NOT NULL
		,	Remark				VARCHAR(500)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		,	Level				TINYINT									NOT NULL	COMMENT 'Level 1 - 2'
		,	FromCustID			BIGINT		UNSIGNED					NOT NULL
		,	CreatedDate			DATETIME								NOT NULL
		,	CreatedBy			INT										NOT NULL 
        ,	PRIMARY KEY			PK_CustEvidence(CTSCustID, FromCustID, EvidenceID)
	);
    
	#===1. GET List of New Association=====================================================================
    SET lv_LastCTSAssDevID = (SELECT LastCTSAssDevID FROM CTS_DataCenter.ProcessAffectedEvidence LIMIT 1);
    
    INSERT INTO Temp_AssociationByDevice(CTSAssDevID, FromCTSCustID, DCSDeviceID)
    SELECT	ad.CTSAssDevID
		,	ad.CTSCustID AS FromCTSCustID
		,	ad.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS ad
	WHERE ad.CTSAssDevID > lv_LastCTSAssDevID
    LIMIT ip_Batch;    
    
    #===2.GET CTSCust Association with Step1 (CTSCust, Device, Subscriber)=================================
    INSERT INTO	Temp_CustAssociation(FromCTSCustID, ToCTSCustID)
    SELECT	DISTINCT 
			tmp_ad.FromCTSCustID
		,	ad.CTSCustID AS ToCTSCustID
	FROM		Temp_AssociationByDevice	AS tmp_ad
		INNER JOIN CTS_DataCenter.AssociationByDevice AS ad ON tmp_ad.DCSDeviceID = ad.DCSDeviceID
	WHERE	tmp_ad.FromCTSCustID <> ad.CTSCustID;
    
    DELETE tmp_ca
    FROM Temp_CustAssociation AS tmp_ca
		INNER JOIN	CTS_DataCenter.CustException AS ce ON	 ce.LeastCTSCustID_Order = LEAST(tmp_ca.FromCTSCustID, tmp_ca.ToCTSCustID)
														 AND GreatestCTSCustID_Order = GREATEST(tmp_ca.FromCTSCustID, tmp_ca.ToCTSCustID);
                    
                   
    #===3. Place Affected Evidence Level 0  Of (FromCTSCust) for (ToCTSCust)===============================
    IF EXISTS (SELECT 1 FROM Temp_CustAssociation LIMIT 1) THEN     
        
		INSERT IGNORE INTO Temp_CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
		SELECT	tmp_ca.ToCTSCustID
			,	ce.EvidenceID
			,	'Auto New AssDev' AS Remark
			,	2 AS Level
			,	tmp_ca.FromCTSCustID
			,	lv_CreatedDate AS CreatedDate
			,	ce.CreatedBy AS CreatedBy
		FROM CTS_DataCenter.CustEvidence	AS ce
			INNER JOIN	Temp_CustAssociation AS tmp_ca ON ce.CTSCustID = tmp_ca.FromCTSCustID
		WHERE	ce.CTSCustID = tmp_ca.FromCTSCustID
			AND ce.Level = 0;    
			
    #===4. Place Affected Evidence Of Level 0 (ToCTSCust) for (ToCTSCust)==================================
		INSERT IGNORE INTO Temp_CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
		SELECT	tmp_ca.FromCTSCustID
			,	ce.EvidenceID
			,	'Auto New AssDev' AS Remark
			,	2 AS Level
			,	tmp_ca.ToCTSCustID
			,	lv_CreatedDate AS CreatedDate
			,	ce.CreatedBy AS CreatedBy
		FROM CTS_DataCenter.CustEvidence	AS ce
			INNER JOIN	Temp_CustAssociation AS tmp_ca ON ce.CTSCustID = tmp_ca.ToCTSCustID
		WHERE ce.CTSCustID = tmp_ca.ToCTSCustID
			AND ce.Level	= 0;
                    
		IF EXISTS (SELECT 1 FROM Temp_CustEvidence LIMIT 1) THEN  
			DELETE tce
            FROM Temp_CustEvidence AS tce
				INNER JOIN CTS_DataCenter.CustEvidence  AS ce ON tce.CTSCustID = ce.CTSCustID AND tce.FromCustID = ce.FromCustID AND tce.EvidenceID = ce.EvidenceID;            
            
			INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
			SELECT	tce.CTSCustID
				,	tce.EvidenceID
				,	tce.Remark
				,	tce.Level
				,	tce.FromCustID
				,	tce.CreatedDate
				,	tce.CreatedBy
			FROM	Temp_CustEvidence	AS tce;	
            
			SELECT cus.CustID
			FROM (SELECT DISTINCT CTSCustID FROM Temp_CustEvidence)	AS tce
				INNER JOIN	CTS_DataCenter.CTSCustomer AS cus ON tce.CTSCustID = cus.CTSCustID;	
		END IF;
	END IF;
    
	#=====Update ProcessAffectedEvidence ===============================================
    UPDATE	CTS_DataCenter.ProcessAffectedEvidence
    SET		LastCTSAssDevID = (SELECT IFNULL(MAX(CTSAssDevID),LastCTSAssDevID) FROM Temp_AssociationByDevice);
    
    

END$$

DELIMITER ;