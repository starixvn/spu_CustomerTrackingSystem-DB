/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Remove_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_CustInfo				JSON
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- CTS_DC_CustClassification_Remove_GetInfo ();
*/
	
	DECLARE CONST_CATEID_VVIP 							INT;
	
	SET CONST_CATEID_VVIP 								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClassification;
	CREATE TEMPORARY TABLE Temp_CustomerClassification (
			CustID								BIGINT UNSIGNED PRIMARY KEY
		, 	CTSCustID							BIGINT UNSIGNED
		, 	SubscriberID						INT UNSIGNED
		,	RoleID								INT	
		,	Remark 								VARCHAR(500) 
		,	CreatedBy 							INT UNSIGNED
		,	IsExistVVIP							TINYINT(1) 
		,	IsLicenseeVIP						TINYINT(1) 
		,	IsLicenseeBA						TINYINT(1) 
		,	IsExceptDirectDownline				TINYINT(1) DEFAULT NULL
        ,	IsMarkedDirectly					TINYINT(1) DEFAULT NULL
		,	IsRemovedPA							TINYINT(1) DEFAULT 0
		,	CategoryID 							INT UNSIGNED
		,	Ext_EvidenceID_Licensee 			SMALLINT UNSIGNED	
		,	Ext_EvidenceID_Credit				SMALLINT UNSIGNED
		,	IsCleanPA							TINYINT(1) DEFAULT 1
		,	IsDangerProbation					TINYINT(1)
		,	CategoryPriority					SMALLINT UNSIGNED
		,	CustomerClass						SMALLINT UNSIGNED
		,	IsReturnData						TINYINT(1) DEFAULT 0
		,	IsExistRobot						TINYINT(1) DEFAULT 0
		,	IsFromTW							TINYINT(1) DEFAULT 0
		,	IsFromTVS							TINYINT(1) DEFAULT 0
		,	IsFromAI							TINYINT(1) DEFAULT 0
		,	IsFromCTS							TINYINT(1) DEFAULT 0
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			CustID								BIGINT UNSIGNED PRIMARY KEY
		, 	CTSCustID							BIGINT UNSIGNED
		, 	SubscriberID						INT UNSIGNED
		,	RoleID								INT	
		,	Remark 								VARCHAR(500) 
		,	CreatedBy 							INT UNSIGNED
		,	IsLicenseeVIP						TINYINT(1) 
		,	IsLicenseeBA						TINYINT(1) 
		,	IsExceptDirectDownline				TINYINT(1) DEFAULT NULL
        ,	IsMarkedDirectly					TINYINT(1) DEFAULT NULL
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_KeepDirect;
	CREATE TEMPORARY TABLE Temp_KeepDirect(
			CustID 								BIGINT UNSIGNED PRIMARY KEY
	);
	
	IF ip_InputFlowID = 221 THEN /*VVIP*/
		INSERT INTO Temp_CustomerClassification(CustID, CTSCustID, CreatedBy, CategoryID, IsExistVVIP, IsReturnData)
		SELECT DISTINCT temp.CustID, temp.CTSCustID, temp.CreatedBy, 1 AS IsReturnData
			, 	cls.CategoryID
			, 	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsExistVVIP
		FROM JSON_TABLE(ip_CustInfo,
						"$[*]" COLUMNS(
											CustID 				BIGINT UNSIGNED				PATH "$.CustID"
										,	CTSCustID 			BIGINT UNSIGNED				PATH "$.CTSCustID"
										,	CreatedBy 			INT UNSIGNED				PATH "$.CreatedBy"
										)) AS temp
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																			AND cls.CategoryID = CONST_CATEID_VVIP;     
	
	ELSEIF ip_InputFlowID = 222 THEN /*SpecialCC*/
		INSERT INTO Temp_CustomerClassification(CustID, CTSCustID, SubscriberID, CreatedBy, Remark, IsReturnData)
		SELECT temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.CreatedBy, temp.Remark, 1 AS IsReturnData
		FROM JSON_TABLE(ip_CustInfo,
						"$[*]" COLUMNS(
											CTSCustID				BIGINT UNSIGNED			PATH '$.CTSCustID'
										,	CustID					BIGINT UNSIGNED			PATH '$.CustID'
										,	SubscriberID			INT	UNSIGNED			PATH '$.SubscriberID'
										,	Remark					VARCHAR(500)			PATH '$.Remark'
										,	CreatedBy 				INT UNSIGNED			PATH "$.CreatedBy"
										)) AS temp;    

	ELSEIF ip_InputFlowID = 223 THEN /*LicVIP*/
		INSERT INTO Temp_Customer(CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP)
		SELECT temp.CustID, cus.CTSCustID, cus.SubscriberID, temp.CreatedBy, cus.IsLicenseeVIP
		FROM JSON_TABLE(ip_CustInfo,
						"$[*]" COLUMNS(
											CustID					BIGINT UNSIGNED			PATH '$.CustID'
										,	CreatedBy 				INT UNSIGNED			PATH "$.CreatedBy"
										)) AS temp
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON temp.CustID = cus.CustID AND cus.CustSubID = 0;   
	
	ELSEIF ip_InputFlowID = 224 THEN /*LicBA*/
		INSERT INTO Temp_Customer(CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeBA)
		SELECT temp.CustID, cus.CTSCustID, cus.SubscriberID, temp.CreatedBy, cus.IsLicenseeBA
		FROM JSON_TABLE(ip_CustInfo,
						"$[*]" COLUMNS(
											CustID					BIGINT UNSIGNED			PATH '$.CustID'
										,	CreatedBy 				INT UNSIGNED			PATH "$.CreatedBy"
										)) AS temp
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON temp.CustID = cus.CustID AND cus.CustSubID = 0;   
										
	ELSEIF ip_InputFlowID = 225 THEN /*PA*/
		INSERT INTO Temp_Customer(CustID, CTSCustID, RoleID, SubscriberID, CreatedBy, Remark, IsExceptDirectDownline, IsMarkedDirectly)
		SELECT DISTINCT temp.CustID, temp.CTSCustID, temp.RoleID, temp.SubscriberID, temp.CreatedBy, temp.Remark, temp.IsExceptDirectDownline, temp.IsMarkedDirectly
		FROM JSON_TABLE(ip_CustInfo,
						"$[*]" COLUMNS(
											CustID 					BIGINT UNSIGNED		PATH "$.CustID"
										, 	CTSCustID				BIGINT UNSIGNED 	PATH "$.CTSCustID"
										,   RoleID 					INT					PATH "$.RoleID"
										,   SubscriberID 			INT	UNSIGNED		PATH "$.SubscriberID"
										, 	CreatedBy				INT UNSIGNED		PATH "$.CreatedBy"
										, 	Remark					VARCHAR(500)		PATH "$.Remark"
										, 	IsExceptDirectDownline	TINYINT(1) 			PATH "$.IsExceptDirectDownline"
										, 	IsMarkedDirectly		TINYINT(1) 			PATH "$.IsDirectPA"
										)) AS temp
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																			AND cls.CategoryID = CONST_CATEID_VVIP
		WHERE cls.CustID IS NULL;    
	END IF;

END$$
DELIMITER ;