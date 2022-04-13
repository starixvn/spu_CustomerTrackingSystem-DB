/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_ProblemAccountManagement_Evidence_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemAccountManagement_Evidence_Update`(
		IN ip_CustInfo		JSON
	,	IN ip_ModifiedBy	INT UNSIGNED
    ,	IN ip_SourceType    SMALLINT UNSIGNED
)
    SQL SECURITY INVOKER
sp :BEGIN
/*
		Created:	20220322@Aries.Nguyen
		Task:		Allow Unmark and Update on PA Management Function [Redmine ID: #170135]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220322@Aries.Nguyen: Created [Redmine ID: #170135]

        Param's Explanation (filtered by):
			- ip_SourceType: 1 - NAP, 0 - Others
        Example: 
			- CALL CTS_DC_ProblemAccountManagement_Evidence_Update('[{"CustID":1384, "FromReasonID":103, "ToReasonID":106}]',555,1);
*/   
	DECLARE lv_CustRemove       LONGTEXT;
    DECLARE lv_SourceTypeStr    VARCHAR(20) DEFAULT "Evidence";
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceExist;    
	CREATE TEMPORARY TABLE Temp_CustEvidenceExist(	 
			CustEvidID	BIGINT UNSIGNED PRIMARY KEY
		,	CTSCustID	BIGINT UNSIGNED 
        ,	EvidenceID  SMALLINT
        ,	UNIQUE KEY	UN_Temp_CustEvidenceExist_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustParam;    
	CREATE TEMPORARY TABLE Temp_CustParam( 	  
			CustID			BIGINT UNSIGNED
        , 	CTSCustID		BIGINT UNSIGNED
        ,	OldEvidenceID	INT 
        ,	EvidenceID		INT 
        ,	EviLevel		TINYINT DEFAULT 0
        ,   PRIMARY KEY(CTSCustID,EvidenceID)
	);
    
    IF ip_SourceType = 1 THEN
        SET lv_SourceTypeStr = 'NAP'
    END IF;

    INSERT IGNORE INTO Temp_CustParam(CustID,CTSCustID,OldEvidenceID,EvidenceID)
	SELECT	info.CustID
		,	cust.CTSCustID
        ,	oldEv.OldEvidenceID
        ,	ev.EvidenceID
	FROM JSON_TABLE(ip_CustInfo,
		 "$[*]" COLUMNS(
				CustID			VARCHAR(50)		PATH "$.CustID" 
			, 	FromReasonID	INT				PATH "$.FromReasonID"
            ,	ToReasonID		INT				PATH "$.ToReasonID")
	) AS info
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON info.CustID = cust.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.MappingSubscriberSite AS m ON cust.SiteID = m.SiteID,
        LATERAL (SELECT  CASE WHEN m.SubscriberGroupID = 2  THEN cate.EvidenceID_Licensee ELSE cate.EvidenceID_Credit END AS EvidenceID
                 FROM CTS_DataCenter.CustomerCategory AS cate 
                 WHERE cate.ReasonID = info.ToReasonID  AND cate.SourceType = lv_SourceTypeStr
                    AND (cate.EvidenceID_Licensee IS NOT NULL OR  cate.EvidenceCode_Credit  IS NOT NULL)
                 LIMIT 1) AS ev,
		LATERAL (SELECT  CASE WHEN m.SubscriberGroupID = 2  THEN cate.EvidenceID_Licensee ELSE cate.EvidenceID_Credit END AS OldEvidenceID
                 FROM CTS_DataCenter.CustomerCategory AS cate 
                 WHERE cate.ReasonID = info.FromReasonID AND cate.SourceType = lv_SourceTypeStr
                    AND (cate.EvidenceID_Licensee IS NOT NULL OR  cate.EvidenceCode_Credit  IS NOT NULL)
                 LIMIT 1) AS oldEv;
    
    /*******************Remove Evidence FromReasonID*******************************/
    INSERT INTO Temp_CustEvidenceExist(CustEvidID,CTSCustID,EvidenceID)
	SELECT 	ev.CustEvidID
		,	ev.CTSCustID
        ,	ev.EvidenceID
	FROM CTS_DataCenter.CustEvidence AS ev 
	WHERE EXISTS (SELECT 1 
				  FROM Temp_CustParam AS tmp 
                  WHERE tmp.OldEvidenceID IS NOT NULL
					AND ev.CTSCustID = tmp.CTSCustID 
					AND ev.EvidenceID = tmp.OldEvidenceID
					AND ev.Level = tmp.EviLevel
                    AND ev.SourceType = 1);
	 
    DELETE 
    FROM CTS_DataCenter.CustEvidence AS ev
    WHERE EXISTS (SELECT 1 FROM Temp_CustEvidenceExist AS tmp WHERE tmp.CustEvidID = ev.CustEvidID);
    
    INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID, EvidenceID)
    SELECT 	tmp.CTSCustID
		,	tmp.EvidenceID
    FROM Temp_CustEvidenceExist AS tmp;
    
    TRUNCATE TABLE Temp_CustEvidenceExist;
     /*******************Insert Evidence ToReasonID*******************************/
    CALL CTS_DC_ExcludeCustByCondition('Temp_CustParam');
    
	DELETE tmp
    FROM Temp_CustParam AS tmp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = tmp.CTSCustID; 
    
    INSERT INTO Temp_CustEvidenceExist(CustEvidID,CTSCustID,EvidenceID)
	SELECT 	ev.CustEvidID
		,	ev.CTSCustID
        ,	ev.EvidenceID
	FROM CTS_DataCenter.CustEvidence AS ev 
	WHERE EXISTS (SELECT 1 
				  FROM Temp_CustParam AS tmp 
                  WHERE  tmp.EvidenceID IS NOT NULL
					AND ev.CTSCustID = tmp.CTSCustID 
					AND ev.EvidenceID = tmp.EvidenceID
					AND ev.Level = tmp.EviLevel
                    AND ev.SourceType = 0);
	
    DELETE 
    FROM CTS_DataCenter.CustEvidence AS ev
    WHERE EXISTS (SELECT 1 FROM Temp_CustEvidenceExist AS tmp WHERE tmp.CustEvidID = ev.CustEvidID);
    
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, SourceType)
	SELECT 	tmp.CTSCustID
		,	tmp.EvidenceID
        ,	"Add from Problem Account Management"
        ,	0 
        ,	tmp.CTSCustID
        ,	NOW()
        ,	ip_ModifiedBy
        ,	ip_SourceType
    FROM Temp_CustParam AS tmp
	WHERE tmp.EvidenceID IS NOT NULL;
					 
	INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueInsert(CTSCustID,  EvidenceID, Remark, CreatedBy)
	SELECT 	tmp.CTSCustID
		,	tmp.EvidenceID
        ,	"Add from Problem Account Management"
        ,	ip_ModifiedBy
    FROM Temp_CustParam AS tmp
    WHERE  tmp.EvidenceID IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_CustEvidenceExist AS ex WHERE ex.CTSCustID = tmp.CTSCustID AND ex.EvidenceID = tmp.EvidenceID);

    SELECT	DISTINCT
            tmp.CustID 
    FROM Temp_CustParam AS tmp
    WHERE tmp.EvidenceID IS NOT NULL;
END$$
DELIMITER ;