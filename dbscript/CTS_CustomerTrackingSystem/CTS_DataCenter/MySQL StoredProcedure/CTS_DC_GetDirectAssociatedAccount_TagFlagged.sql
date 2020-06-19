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
			- 20200619@Harvey: remove BLACKFLAGGED for evidence 100				[Redmine: 133935]
		Param's Explanation (filtered by):
	*/
    #DECLARE		vrIsFlagged			TINYINT DEFAULT -1 ;  # 0: NOT Flag, 1: BlackFlaged, 2: Flagged; 
	DECLARE		vrIsFlagged			TINYINT DEFAULT -1 ;  # 0: NOT Flag, 1: BlackFlaged, 2: Flagged;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
    CREATE TEMPORARY TABLE Temp_CTSCustomer(
		CTSCustID			BIGINT UNSIGNED
        , SubscriberID		INT
        , FlaggedTag		TINYINT	DEFAULT 0
    );
    
    
    INSERT INTO Temp_CTSCustomer(
				CTSCustID 
				, SubscriberID
				)
	SELECT 	tmpCust.CTSCustID
			, tmpCust.SubscriberID
			 FROM
			   JSON_TABLE(
				ip_CTSCustJson,
				 "$[*]" COLUMNS(
				  CTSCustID 			BIGINT UNSIGNED PATH "$.CTSCustId"         
				, SubscriberID			INT PATH "$.SubscriberId"
				 )
			   ) AS  tmpCust;    
    
	/*Check If Account IS IS  FLAG*/
    UPDATE		Temp_CTSCustomer 		AS tmpCust
	INNER JOIN	CTS_DataCenter.CustEvidence AS ced
				ON	ced.SubscriberID	= tmpCust.SubscriberID
				AND ced.CTSCustID		= tmpCust.CTSCustID
	SET			tmpCust.FlaggedTag = 2
    WHERE		ced.Level = 0
				AND tmpCust.FlaggedTag = 0;
	 
	SELECT 	tmpCust.SubscriberID
			, tmpCust.CTSCustID
            , tmpCust.FlaggedTag
    FROM	Temp_CTSCustomer AS tmpCust;
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;