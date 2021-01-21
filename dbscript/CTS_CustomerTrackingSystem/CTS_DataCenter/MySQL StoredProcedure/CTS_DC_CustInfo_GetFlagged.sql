/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_GetFlagged`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_GetFlagged`(IN ip_CTSCustID INT)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Get Flag Info By CTSCustID
		DB:			CTS_DataCenter
		Original: Spec https://nexdev.net/projects/customer-tracking-system/wiki/CTS_-_General_Information_Panel
					IF account has 
		Revisions:
			- 20200706@Lex: Fix logic return flag and affected evidence for root account [Redmine ID: #137055]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]

		Param's Explanation (filtered by):
	*/
    
    DECLARE		vrIsFlagged			BIT DEFAULT 0 ;  # 0: NOT Flagged, 1: Flagged; 
    DECLARE		vrIsAffected		BIT DEFAULT 0 ;  # 0: NOT Affected, 1: Affected; 
 
	 /*Check If Account IS IS  FLAG*/
		SET vrIsFlagged = IFNULL((SELECT	1
							FROM	CTS_DataCenter.CustEvidence AS ced
                            INNER JOIN	CTS_DataCenter.Evidence	AS  evd
								ON ced.EvidenceID = evd.EvidenceID
							WHERE 	ced.CTSCustID		= ip_CTSCustID        
                                AND ced.Level = 0
							LIMIT 1), 0);
    
    /*Check If Account IS IS Affected*/
		SET vrIsAffected = IFNULL((SELECT	1
							FROM	CTS_DataCenter.CustEvidence AS ced
                            INNER JOIN	CTS_DataCenter.Evidence	AS  evd
								ON ced.EvidenceID = evd.EvidenceID
							LEFT JOIN CTS_DataCenter.CustRetractEvidence AS crev
								ON ced.CTSCustID = crev.CTSCustID
									AND ced.EvidenceID = crev.EvidenceID
							WHERE 	ced.CTSCustID		= ip_CTSCustID        
                                AND ced.Level = 2
                                AND crev.CTSCustID IS NULL
							LIMIT 1), 0);
    
    SELECT vrIsFlagged AS Flagged, vrIsAffected AS Affected;
    
END$$

DELIMITER ;

