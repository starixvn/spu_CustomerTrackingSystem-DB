DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerFlagInfo$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerFlagInfo(IN ip_SubscriberID INT, IN ip_CTSCustID INT)
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Get Flag Info By CTSCustID
		DB:			CTS_DataCenter
		Original: Spec https://nexdev.net/projects/customer-tracking-system/wiki/CTS_-_General_Information_Panel
					IF account has 
		Revisions:
		Param's Explanation (filtered by):
	*/
    DECLARE		vrIsFlagged			TINYINT DEFAULT -1 ;  # 0: NOT Flag, 1: BlackFlaged, 2: Flagged; 
 
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    /*Check If Account IS IS BLACK FLAG*/
    SET vrIsFlagged		 = IFNULL(	(SELECT 	1
									FROM		CTS_DataCenter.CustEvidence AS ced
									INNER JOIN	CTS_DataCenter.Evidence	AS  evd
												ON ced.EvidenceID = evd.EvidenceID
									WHERE 	ced.SubscriberID		= ip_SubscriberID
											AND ced.CTSCustID		= ip_CTSCustID                                
											AND evd.EvidenceCode	= 100
                                            AND evd.EvidenceGroupID	= 99
                                            AND ced.Level = 0
									LIMIT 1),0);              
                                    
	 /*Check If Account IS IS  FLAG*/
    IF (vrIsFlagged = 0) THEN
		SET vrIsFlagged = IFNULL(	(	SELECT  	2
										FROM		CTS_DataCenter.CustEvidence AS ced
										INNER JOIN	CTS_DataCenter.Evidence	AS  evd
													ON ced.EvidenceID = evd.EvidenceID
										WHERE 	ced.SubscriberID		= ip_SubscriberID
												AND ced.CTSCustID		= ip_CTSCustID        
                                                AND ced.Level = 0
										LIMIT 1),0);
	END IF;   
    
    SELECT vrIsFlagged AS Flagged; 
	 
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;