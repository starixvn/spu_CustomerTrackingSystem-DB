DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetDirectAssociatedAccount_TagFlagged$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetDirectAssociatedAccount_TagFlagged(IN ip_CTSCustJson LONGTEXT)
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Reurn Tags Flagged Of CTSCustList
		DB:			CTS_DataCenter
		Original:	
		Revisions:
		Param's Explanation (filtered by):
	*/
    #DECLARE		vrIsFlagged			TINYINT DEFAULT -1 ;  # 0: NOT Flag, 1: BlackFlaged, 2: Flagged; 
	DECLARE		vrIsFlagged			TINYINT DEFAULT -1 ;  # 0: NOT Flag, 1: BlackFlaged, 2: Flagged;
    
    CREATE TEMPORARY TABLE Temp_CTSCustAssInfo(
		CTSCustID			BIGINT UNSIGNED
        , SubscriberID		INT
        , FlaggedTag		TINYINT	DEFAULT 0
    );
    
    
    INSERT INTO Temp_CTSCustAssInfo(
				CTSCustID 
				, SubscriberID
				)
	SELECT 	tmpTrans.CTSCustID
			, tmpTrans.SubscriberID
			 FROM
			   JSON_TABLE(
				ip_CTSCustJson,
				 "$[*]" COLUMNS(
				  CTSCustID 			BIGINT UNSIGNED PATH "$.CTSCustId"         
				, SubscriberID			INT PATH "$.SubscriberId"
				 )
			   ) AS  tmpTrans;    
               
    /*Check If Account IS IS BLACK FLAG*/
    UPDATE		Temp_CTSCustAssInfo 		AS tmpCust
    INNER JOIN	CTS_DataCenter.CustEvidence AS ced
				ON	ced.SubscriberID	= tmpCust.SubscriberID
					AND ced.CTSCustID	= tmpCust.CTSCustID
    INNER JOIN	CTS_DataCenter.Evidence	AS  evd
				ON ced.EvidenceID = evd.EvidenceID
    SET			tmpCust.FlaggedTag = 1
    WHERE 		evd.EvidenceCode	= 100
				AND evd.EvidenceGroupID	= 99
				AND ced.Level = 0;
    
	/*Check If Account IS IS  FLAG*/
    UPDATE		Temp_CTSCustAssInfo 		AS tmpCust
	INNER JOIN	CTS_DataCenter.CustEvidence AS ced
				ON	ced.SubscriberID	= tmpCust.SubscriberID
				AND ced.CTSCustID		= tmpCust.CTSCustID
	SET			tmpCust.FlaggedTag = 2
    WHERE		ced.Level = 0;
	 
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;