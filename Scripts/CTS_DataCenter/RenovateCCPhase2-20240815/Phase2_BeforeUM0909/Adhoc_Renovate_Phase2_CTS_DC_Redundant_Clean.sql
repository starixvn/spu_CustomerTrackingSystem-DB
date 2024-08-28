/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_Redundant_Clean`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_Redundant_Clean`(
    	IN	ip_Batchsize					INT
    ,	IN	ip_MinCustID					BIGINT
    ,	OUT	op_MaxCustID					BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240826@Victoria.Le
		Task:		Clean CCMain/History Redundant - General + BySport
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_Redundant_Clean(1000,9999,op_MaxCustID);
			
		Revisions: 
			- 20240826@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/

	DECLARE lv_FromCustID					BIGINT DEFAULT 0;
	DECLARE lv_ToCustID						BIGINT DEFAULT 0;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer_Archive;    
	CREATE TEMPORARY TABLE Temp_Customer_Archive(	  
			ArchiveID					BIGINT UNSIGNED PRIMARY KEY
		,	CustID						BIGINT 
		,	CTSCustID					BIGINT 
		,	AccountID					BIGINT
		,	TypeCC						TINYINT /*1: GENERAL 2: BYSPORT 3: BOTH*/
		,	RoleID						TINYINT
		,	INDEX IX_Temp_Customer_Archive_AccountID (AccountID)
		,	INDEX IX_Temp_Customer_Archive_CustID (CustID)
		,	INDEX IX_Temp_Customer_Archive_CTSCustID (CTSCustID)
	);
	
	WITH CTE AS
	(
		SELECT ad.CustID
		FROM CTS_DataCenter.AdhocVic_Customer AS ad 
		WHERE ad.CustID >= ip_MinCustID
		ORDER BY ad.CustID
		LIMIT ip_Batchsize
	)
	SELECT MIN(c.CustID), MAX(c.CustID)
	INTO lv_FromCustID, lv_ToCustID
	FROM CTE AS c;
	
	INSERT INTO Temp_Customer_Archive (ArchiveID, CustID, CTSCustID, AccountID, TypeCC, RoleID)
	SELECT ar.ID, ad.CustID, ar.CTSCustID, ar.AccountID, ad.TypeCC, ar.RoleID
	FROM CTS_DataCenter.AdhocVic_Customer AS ad 
		INNER JOIN CTS_DataCenter.ArchiveCustomer_CTSCustomer AS ar ON ar.CustID = ad.CustID 
																		AND ar.CustSubID = 0
	WHERE ad.CustID >= lv_FromCustID AND ad.CustID <= lv_ToCustID
		AND ar.ArchivedDate = ad.ArchivedDate_Latest
		AND ar.IsReactivated = ad.IsReactivated_Latest
	ORDER BY ad.CustID
	LIMIT ip_Batchsize;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Clean ();
	
	SELECT ad.CustID
	INTO op_MaxCustID
	FROM CTS_Adhoc.AdhocVic_Customer AS ad 
	WHERE ad.CustID > lv_ToCustID
	ORDER BY ad.CustID
	LIMIT 1;
	
	IF op_MaxCustID IS NULL THEN
		SET op_MaxCustID = ip_MinCustID;
	END IF;
	
END$$

DELIMITER ;