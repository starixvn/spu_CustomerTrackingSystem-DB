DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetDirectAssociatedAccount_TagAffected$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetDirectAssociatedAccount_TagAffected(IN ip_AssCTSCustJson LONGTEXT)
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Reurn Tags Flagged Of CTSCustList
		DB:			CTS_DataCenter
		Original:	
		Revisions:
		Param's Explanation (filtered by):
			Input: (ip_AssCTSCustJson: SubscriberId, FromCTSCustId, ToCTSCustId )
            Output: Distinct FromCTSCustId Within AffectedTag value
	*/

    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustAssInfo;
    CREATE TEMPORARY TABLE Temp_CTSCustAssInfo(
		SubscriberID			INT
		, FromCTSCustID			BIGINT UNSIGNED
        , ToCTSCustID			BIGINT UNSIGNED
        , AffectedTag			TINYINT	DEFAULT 0
    );
        
    INSERT INTO Temp_CTSCustAssInfo(
				SubscriberID
				, FromCTSCustID 
				, ToCTSCustID
				)                
	SELECT 	tmpAss.SubscriberID
			, tmpAss.FromCTSCustID
			, tmpAss.ToCTSCustID
			 FROM
			   JSON_TABLE(
				ip_AssCTSCustJson,
				 "$[*]" COLUMNS(
				SubscriberID 			INT SIGNED PATH "$.SubscriberId"
				, FromCTSCustID 		BIGINT UNSIGNED PATH "$.FromCTSCustId"         
				, ToCTSCustID 			BIGINT UNSIGNED PATH "$.ToCTSCustId"   
				 )
			   ) AS  tmpAss;    
               
    /*Check If Account IS AFFECTED*/
    UPDATE		Temp_CTSCustAssInfo 		AS tmpCust
    INNER JOIN	CTS_DataCenter.CustEvidence AS ced
				ON	ced.SubscriberID	= tmpCust.SubscriberID
					AND ced.CTSCustID	= tmpCust.ToCTSCustID
    INNER JOIN	CTS_DataCenter.Evidence	AS  evd
				ON ced.EvidenceID	= evd.EvidenceID
    SET			tmpCust.AffectedTag	= 1
    WHERE 		ced.Level = 0;
    
    /*Return AFFECTED Info*/
    SELECT		tmpCust.FromCTSCustID
				, MAX(tmpCust.AffectedTag) 	AS AffectedTag
    FROM		Temp_CTSCustAssInfo 		AS tmpCust
    GROUP BY	tmpCust.FromCTSCustID;
	 
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;