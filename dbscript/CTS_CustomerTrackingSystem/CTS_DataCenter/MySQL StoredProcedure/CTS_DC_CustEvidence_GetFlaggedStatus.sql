/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_GetFlaggedStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetFlaggedStatus`(IN ip_CTSCustJson longtext)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191225@Casey.Huynh	
		Task :		Return flagged tag associated account list
		DB:			CTS_DataCenter
		Original:	
		Revisions:
			- 20200619@Harvey: remove BLACKFLAGGED for evidence 100
            - 20200707@Lex: fix wrong tagged info return [Redmine ID: #137055]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
		
		Param's Explanation (filtered by):
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
    CREATE TEMPORARY TABLE Temp_CTSCustomer(
			CTSCustID		BIGINT UNSIGNED
		,	SubscriberID	INT
        ,	IsFlagged		BIT DEFAULT 0
        ,	IsAffected		BIT DEFAULT 0
        ,	INDEX TMP_CTSCustID_TaggedFlag(CTSCustID, SubscriberID)
    );
    
    INSERT INTO Temp_CTSCustomer(CTSCustID, SubscriberID)
	SELECT	tmpCust.CTSCustID
		,	tmpCust.SubscriberID
	FROM JSON_TABLE(ip_CTSCustJson, "$[*]" COLUMNS(
							CTSCustID		BIGINT UNSIGNED PATH "$.CTSCustId"         
						,	SubscriberID	INT PATH "$.SubscriberId"
					)) AS  tmpCust;
    
	/* Mark flagged tag for each associated account */
    UPDATE Temp_CTSCustomer AS tmpCust, 
	LATERAL	(SELECT ce.CTSCustID
				,	MAX(CASE WHEN ce.Level = 0 THEN 1 ELSE 0 END) AS IsFlagged
				,	MAX(CASE WHEN ce.Level = 2 THEN 1 ELSE 0 END) AS IsAffected
				 FROM CTS_DataCenter.CustEvidence AS ce
                 LEFT JOIN CTS_DataCenter.CustRetractEvidence AS crev
					ON ce.CTSCustID = crev.CTSCustID
						AND ce.EvidenceID = crev.EvidenceID
                        AND ce.Level = 2
                 WHERE ce.CTSCustID	= tmpCust.CTSCustID
                    AND crev.CTSCustID IS NULL
				GROUP BY ce.CTSCustID) as ce
	SET tmpCust.IsFlagged = ce.IsFlagged
    ,	tmpCust.IsAffected = ce.IsAffected;
	
    SELECT	CTSCustID
		,	SubscriberID
        ,	IsFlagged
        ,	IsAffected
	FROM Temp_CTSCustomer;

END$$

DELIMITER ;

