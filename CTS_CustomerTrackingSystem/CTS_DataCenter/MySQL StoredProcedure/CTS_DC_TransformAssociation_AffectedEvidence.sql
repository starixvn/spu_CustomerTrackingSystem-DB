DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociation_AffectedEvidence$$
CREATE PROCEDURE CTS_DataCenter.CTS_DC_TransformAssociation_AffectedEvidence(IN ip_Batch INT)
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Place Affected Evidence for New AssociationByDevice
		DB:			CTS_DataCenter
		Original: 
		Revisions:	
					[20200303@Casey.Huynh]. Update Affected CreateBy = Root CreatedBy
		Param's Explanation (filtered by):
	*/
    
    #===0.Declare==========================================================================================
    DECLARE	vr_LastCTSAssDevID BIGINT UNSIGNED;
    DECLARE	vr_CreatedDate	DATETIME;
    DECLARE	vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_TransformAssociation_AffectedEvidence';
    
    SET	vr_CreatedDate = CURRENT_TIME();
    
	DROP TEMPORARY TABLE IF EXISTS TempAssociationByDevice;    
	CREATE TEMPORARY TABLE TempAssociationByDevice
	( 	
		CTSAssDevID		BIGINT	UNSIGNED
        , FromCTSCustID	BIGINT	UNSIGNED
        , DCSDeviceID	BIGINT	UNSIGNED
        , SubscriberID	INT
	);
	
	DROP TEMPORARY TABLE IF EXISTS TempCustAssociation;    
	CREATE TEMPORARY TABLE TempCustAssociation
	( 	
		FromCTSCustID		BIGINT	UNSIGNED
        , ToCTSCustID		BIGINT	UNSIGNED
        , SubscriberID		INT
	);	
    
	#===1. GET List of New Association=====================================================================
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

    SET vr_LastCTSAssDevID = (SELECT LastCTSAssDevID FROM CTS_DataCenter.ProcessAffectedEvidence LIMIT 1);
    
    INSERT INTO TempAssociationByDevice(CTSAssDevID, FromCTSCustID, DCSDeviceID, SubscriberID)
    SELECT		ad.CTSAssDevID
				, ad.CTSCustID		AS FromCTSCustID
                , ad.DCSDeviceID
                , ad.SubscriberID
    FROM		CTS_DataCenter.AssociationByDevice AS ad
	WHERE		ad.CTSAssDevID > vr_LastCTSAssDevID
    LIMIT		ip_Batch;    
    
    #===2.GET CTSCust Association with Step1 (CTSCust, Device, Subscriber)=================================
    INSERT INTO	TempCustAssociation(FromCTSCustID, ToCTSCustID, SubscriberID)
    SELECT		DISTINCT tmp_ad.FromCTSCustID
						, ad.CTSCustID AS ToCTSCustID
						, tmp_ad.SubscriberID
	FROM		TempAssociationByDevice	AS tmp_ad
    INNER JOIN	CTS_DataCenter.AssociationByDevice AS ad
				ON tmp_ad.DCSDeviceID = ad.DCSDeviceID
					AND tmp_ad.SubscriberID = ad.SubscriberID
	WHERE		tmp_ad.FromCTSCustID <> ad.CTSCustID;
    
    DELETE 		tmp_ca
    FROM		TempCustAssociation 			AS tmp_ca
    INNER JOIN	CTS_DataCenter.CustException	AS ce
				ON	ce.LeastCTSCustID_Order = LEAST(tmp_ca.FromCTSCustID, tmp_ca.ToCTSCustID)
					AND GreatestCTSCustID_Order = GREATEST(tmp_ca.FromCTSCustID, tmp_ca.ToCTSCustID);
                    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;                
    #===3. Place Affected Evidence Level 0  Of (FromCTSCust) for (ToCTSCust)===============================
    IF EXISTS (SELECT 1 FROM TempCustAssociation LIMIT 1) THEN        
		INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, SubscriberID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, IsCreatedByMaster)
		SELECT	tmp_ca.ToCTSCustID
				, ce.SubscriberID
				, ce.EvidenceID
				, 'Auto New AssDev' AS Remark
				, 2 				AS Level
				, tmp_ca.FromCTSCustID
				, vr_CreatedDate	AS CreatedDate
				, ce.CreatedBy 		AS CreatedBy
                , ce.IsCreatedByMaster 
		FROM		CTS_DataCenter.CustEvidence	AS ce
		INNER JOIN	TempCustAssociation AS tmp_ca
					ON		ce.CTSCustID 	= tmp_ca.FromCTSCustID
						AND ce.SubscriberID = tmp_ca.SubscriberID
		WHERE		ce.CTSCustID	= tmp_ca.FromCTSCustID
					AND ce.Level	= 0;    
			
    #===4. Place Affected Evidence Of Level 0 (ToCTSCust) for (ToCTSCust)==================================
		INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, SubscriberID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, IsCreatedByMaster)
			SELECT	tmp_ca.FromCTSCustID
					, ce.SubscriberID
					, ce.EvidenceID
					, 'Auto New AssDev' AS Remark
					, 2 				AS Level
					, tmp_ca.ToCTSCustID
					, vr_CreatedDate	AS CreatedDate
					, ce.CreatedBy 		AS CreatedBy
                    , ce.IsCreatedByMaster
			FROM		CTS_DataCenter.CustEvidence	AS ce
			INNER JOIN	TempCustAssociation AS tmp_ca
						ON	ce.CTSCustID = tmp_ca.ToCTSCustID
							AND ce.SubscriberID = tmp_ca.SubscriberID
			WHERE		ce.CTSCustID	= tmp_ca.ToCTSCustID
						AND ce.Level	= 0;	
	#=====Update ProcessAffectedEvidence ===============================================
    UPDATE	CTS_DataCenter.ProcessAffectedEvidence
    SET		LastCTSAssDevID = (SELECT MAX(CTSAssDevID) FROM TempAssociationByDevice);
    
	END IF;

END$$	
DELIMITER ;