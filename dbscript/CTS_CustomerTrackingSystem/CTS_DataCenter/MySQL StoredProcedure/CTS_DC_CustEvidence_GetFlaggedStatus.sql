/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_GetFlaggedStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetFlaggedStatus`(
		IN ip_CTSCustJson LONGTEXT
)
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
			- 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DC_CustEvidence_GetFlaggedStatus('[{"CTSCustId":47265619,"SubscriberId":162},{"CTSCustId":47606477,"SubscriberId":4423},{"CTSCustId":48923081,"SubscriberId":4423}]');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
    CREATE TEMPORARY TABLE Temp_CTSCustomer(
			CTSCustID		BIGINT UNSIGNED
		,	SubscriberID	INT
        ,	INDEX 			IX_Temp_CTSCustomer_CTSCustID(CTSCustID)
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustInfo;
    CREATE TEMPORARY TABLE Temp_CTSCustInfo(
			CTSCustID		BIGINT UNSIGNED
		,	SubscriberID	INT
		,	IsFlagged		BIT DEFAULT 0
        ,	IsAffected		BIT DEFAULT 0
		,	INDEX			IX_Temp_CTSCustInfo_CTSCustID(CTSCustID)
	);

    INSERT INTO Temp_CTSCustomer(CTSCustID, SubscriberID)
	SELECT	tmpCust.CTSCustID
		,	tmpCust.SubscriberID
	FROM JSON_TABLE(ip_CTSCustJson, 
		"$[*]" COLUMNS(
				CTSCustID		BIGINT UNSIGNED		PATH "$.CTSCustId"         
			,	SubscriberID	INT					PATH "$.SubscriberId"
		)
	) AS  tmpCust;
    
	/* Mark flagged tag for each associated account */
	INSERT INTO Temp_CTSCustInfo(CTSCustID, SubscriberID, IsFlagged, IsAffected)
	SELECT 	tmpCust.CTSCustID
		,	tmpCust.SubscriberID
		,	ce.IsFlagged
		,	ce.IsAffected
    FROM Temp_CTSCustomer AS tmpCust, 
		LATERAL	(SELECT ce.CTSCustID
					,	MAX(CASE WHEN ce.Level = 0 THEN 1 ELSE 0 END) AS IsFlagged
					,	MAX(CASE WHEN ce.Level = 2 THEN 1 ELSE 0 END) AS IsAffected
				 FROM CTS_DataCenter.CustEvidence AS ce
					 LEFT JOIN CTS_DataCenter.CustRetractEvidence AS crev ON ce.CTSCustID = crev.CTSCustID AND ce.EvidenceID = crev.EvidenceID AND ce.Level = 2
				 WHERE   ce.CTSCustID = tmpCust.CTSCustID
					 AND crev.CTSCustID IS NULL
				 GROUP BY ce.CTSCustID) AS ce;
	
    SELECT	CTSCustID
		,	SubscriberID
        ,	IsFlagged
        ,	IsAffected
	FROM Temp_CTSCustInfo;
END$$

DELIMITER ;

