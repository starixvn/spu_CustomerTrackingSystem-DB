DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RemoveException$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_RemoveException(IN ip_UserID INT, IN ip_FromCTSCustID BIGINT, IN ip_ToCTSCustID VARCHAR(50))
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		Remove Exception
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
	*/ 
	DECLARE		vr_FromCTSCustID 	BIGINT;
    DECLARE		vr_ToCTSCustID 		BIGINT;
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_RemoveException';
    
    SET	vr_CreatedDate = CURRENT_TIME();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
    CREATE TEMPORARY TABLE Temp_CustDevice
    (	CTSCustID		BIGINT
		, SubscriberID	INT
		, DCSDeviceID	BIGINT
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE Temp_CustAssociation
    (	FromCTSCustID		BIGINT
		, ToCTSCustID		BIGINT
        , SubscriberID		INT
	);
    
    SET vr_FromCTSCustID = LEAST(ip_FromCTSCustID,ip_ToCTSCustID);
    SET	vr_ToCTSCustID = GREATEST(ip_FromCTSCustID,ip_ToCTSCustID);  
    
    #===Remove Exception
    DELETE 	ce
    FROM	CTS_DataCenter.CustException AS ce
    WHERE	ce.LeastCTSCustID_Order 		= vr_FromCTSCustID
			AND ce.GreatestCTSCustID_Order	= vr_ToCTSCustID;
    
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(2,vr_SPName, CONCAT('Remove Exception: ip_FromCTSCustID_', ip_FromCTSCustID, ';ip_ToCTSCustID', ip_ToCTSCustID), vr_CreatedDate, ip_UserID);
    
    #=====Insert Affected Evidence: GET Device And Association into Temp Table
    INSERT INTO Temp_CustDevice(CTSCustID, SubscriberID, DCSDeviceID)
    SELECT 		ad.CTSCustID
				, ad.SubscriberID
				, ad.DCSDeviceID
	FROM		AssociationByDevice AS ad
    WHERE		ad.CTSCustID 	= ip_FromCTSCustID
				OR ad.CTSCustID = ip_ToCTSCustID;         
  
	SELECT * FROM Temp_CustDevice;
    
	INSERT	INTO Temp_CustAssociation(FromCTSCustID, ToCTSCustID, SubscriberID)
    SELECT  	tcd.CTSCustID
				, ad.CTSCustID
                , tcd.SubscriberID
    FROM		Temp_CustDevice 		AS tcd
    INNER JOIN	AssociationByDevice 	AS ad
				ON	tcd.DCSDeviceID			= ad.DCSDeviceID
					AND tcd.SubscriberID	= ad.SubscriberID;
    
    DELETE	tca
    FROM	Temp_CustAssociation AS tca
    WHERE	tca.FromCTSCustID = tca.ToCTSCustID;
    
    #=====Insert Affected Evidence: GET Device And Association into Temp Table
    
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, SubscriberID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT	tca.ToCTSCustID
			, ce.SubscriberID
			, EvidenceID
			, 'By Remove Exception' AS Remark
			, 2 				AS Level
			, ip_FromCTSCustID	AS FromCustID
			, vr_CreatedDate	AS CreatedDate
			, ip_UserID 		AS CreatedBy
    FROM		CTS_DataCenter.CustEvidence	AS ce
    INNER JOIN	Temp_CustAssociation AS tca
				ON ce.CTSCustID = tca.FromCTSCustID
    WHERE		ce.CTSCustID	= ip_FromCTSCustID
				AND ce.Level	= 0;	
    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, SubscriberID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT	ip_FromCTSCustID
			, ce.SubscriberID
			, EvidenceID
			, 'By Remove Exception' AS Remark
			, 2 				AS Level
			, ip_ToCTSCustID	AS FromCustID
			, vr_CreatedDate	AS CreatedDate
			, ip_UserID 		AS CreatedBy
    FROM		CTS_DataCenter.CustEvidence	AS ce
    INNER JOIN	Temp_CustAssociation AS tca
				ON ce.CTSCustID = tca.FromCTSCustID
    WHERE		ce.CTSCustID = ip_ToCTSCustID
				AND ce.Level = 0; 
    
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, vr_SPName, CONCAT('Auto Add by Remove Exception Function: ip_FromCTSCustID_ ', ip_FromCTSCustID, ';ip_ToCTSCustID', ip_ToCTSCustID) , vr_CreatedDate, ip_UserID);
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

END$$	
DELIMITER ;