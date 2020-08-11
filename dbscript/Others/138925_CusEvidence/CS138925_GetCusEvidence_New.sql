DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_Adhoc.CS138925_GetCusEvidence_New$$
CREATE PROCEDURE CTS_Adhoc.CS138925_GetCusEvidence_New()
BEGIN
	/*
		Created:	20200810@Casey.Huynh	
		Task :		GET Evidence BK
		DB:			CTS_DataCenter
		Original: 
		Revisions:	
		Param's Explanation (filtered by):
	*/    
    
    DECLARE vrCustEvidID INT DEFAULT 0;
    DECLARE vrMaxCustEvidID INT ;
    #===0.Declare==========================================================================================
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CS138925_CustEvidence_New(
		CustEvidID			BIGINT		UNSIGNED					NOT NULL
		, CTSCustID			BIGINT		UNSIGNED					NOT NULL
        , SubscriberID		INT										NOT NULL
		, EvidenceID		SMALLINT								NOT NULL
		, Remark			VARCHAR(500)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		, Level				TINYINT									NOT NULL	COMMENT 'Level 1 - 2'
		, FromCustID		BIGINT		UNSIGNED					NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
		, IsCreatedByMaster	TINYINT									NOT NULL
									
        , PRIMARY KEY	PK_CustEvidence_CustEvidID(CustEvidID)
        , UNIQUE INDEX	UX_CustEvidence_CTSCustIDFromCustIDEvidenceID(CTSCustID, FromCustID, EvidenceID)
        , INDEX 		IX_CustEvidence_FromCustIDCTSCustIDEvidenceID(CTSCustID, FromCustID)
	) ENGINE=INNODB;   
    
    SET vrMaxCustEvidID = (SELECT MAX(CustEvidID) FROM CTS_DataCenter.CustEvidence);
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
	WHILE (vrCustEvidID < vrMaxCustEvidID)
    DO
		INSERT IGNORE INTO CTS_Adhoc.CS138925_CustEvidence_New
		SELECT  	ce.*, cus.CTSCustID, cus.SubscriberID
		FROM 		CTS_DataCenter.CustEvidence AS ce
        INNER JOIN 	CTS_DataCenter.CTSCustomer AS cus
					ON ce.CTSCustID = cus.CTSCustID
		WHERE 		CustEvidID > vrCustEvidID
		ORDER BY 	CustEvidID ASC 
		LIMIT 10000;
		
		SET vrCustEvidID = (SELECT MAX(CustEvidID) FROM CTS_DataCenter.CS138925_CustEvidence_New);
    END WHILE;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$	
DELIMITER ;