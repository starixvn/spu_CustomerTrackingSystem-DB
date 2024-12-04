/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DgrAssociation_CheckAssociation`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_DgrAssociation_CheckAssociation`(
		IN ip_BatchSize INT 
	,	OUT op_LastScannedID BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20241203@Thomas.Nguyen
		Task:
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20241203@Thomas.Nguyen: 	Created [Redmine ID: #214353]

		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_DgrAssociation_CheckAssociation(5000,@op_LastScannedID)
	*/ 
    DECLARE	CONST_CATEID_NEW		    INT;
	DECLARE	CONST_PARENTID_WRAPPER		INT;
	DECLARE CONST_ROLEID_MEMBER			SMALLINT DEFAULT 1;
    DECLARE lv_LastScannedID 			BIGINT;

    SET CONST_CATEID_NEW			    = CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_NEW');
	SET CONST_PARENTID_WRAPPER			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');

	DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
	CREATE TEMPORARY TABLE Temp_CustDevice(
			ID						BIGINT
		,	CTSCustID				BIGINT UNSIGNED
		,	DCSDeviceID				BIGINT
		,	PRIMARY KEY(ID)
        ,   KEY IX_Temp_CustDevice_CTSCustID (CTSCustID, DCSDeviceID)
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE Temp_Device(
			DCSDeviceID				BIGINT
		,	PRIMARY KEY(DCSDeviceID)
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE Temp_Cust(
			CTSCustID				BIGINT UNSIGNED
		/*,	DCSDeviceID				BIGINT*/
		,	PRIMARY KEY(CTSCustID)	
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustDgrAssociation;
	CREATE TEMPORARY TABLE 		Temp_CustDgrAssociation (
			CTSCustID			BIGINT UNSIGNED
		/*,	ParentID			INT UNSIGNED
		,	CategoryID   		INT UNSIGNED*/
		,	PRIMARY KEY(CTSCustID/*, ParentID, CategoryID*/)
	);  

    SELECT ParameterValue 
    INTO lv_LastScannedID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 184;

	INSERT IGNORE INTO Temp_CustDevice (ID, CTSCustID, DCSDeviceID)
	SELECT dp.ID, dp.CTSCustID, dp.DCSDeviceID
	FROM CTS_DataCenter.DangerousAssociation_DevicePool AS dp
	WHERE dp.ID > lv_LastScannedID - 10
	ORDER BY dp.ID ASC
	LIMIT ip_BatchSize;

	INSERT IGNORE INTO Temp_Cust (CTSCustID)
	SELECT DISTINCT tmp.CTSCustID
	FROM Temp_CustDevice AS tmp
	WHERE tmp.DCSDeviceID IS NULL;

	INSERT IGNORE INTO Temp_CustDevice (ID, CTSCustID, DCSDeviceID)
	SELECT tmp.CTSCustID, tmp.DCSDeviceID
	FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv	ON dv.CTSCustID = tmp.CTSCustID;

	INSERT IGNORE INTO Temp_Device (DCSDeviceID)
	SELECT DISTINCT DCSDeviceID
	FROM Temp_CustDevice;

    /*Find Cust Null cate from PSR by Device*/
    INSERT IGNORE INTO Temp_CustDetected (ID, CTSCustID, DCSDeviceID)
	SELECT *
	FROM Temp_Device AS tmp
	INNER JOIN CTS_DataCenter.AssociationByDevice AS dv	ON dv.DCSDeviceID = tmp.DCSDeviceID AND dv.CTSCustID <> tmp.CTSCustID
    ,   LATERAL
            (
                SELECT cls.CustID, cls.CategoryID
                FROM CTS_DataCenter.CTSCustomerClassification AS cls
                    INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
                WHERE cls.CTSCustID = tmp.CTSCustID AND cls.ParentID <> CONST_PARENTID_WRAPPER
                ORDER BY  cate.CustomerClassPriority ASC 
                        , cls.LastModifiedDate DESC
                LIMIT 1
            ) AS cate
        INNER JOIN CTS_DataCenter.CustomerCategorySettings AS st ON st.CategoryID = cate.CategoryID AND st.FlowNormalDgrAssociation = 1 AND st.CategoryID <> CONST_CATEID_NEW
    WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassification AS cls WHERE cls.CTSCustID = dv.CTSCustID);



	INSERT IGNORE INTO Temp_CustNewCate (ID, CTSCustID, DCSDeviceID)
	SELECT *
	FROM Temp_Device AS tmp
	INNER JOIN CTS_DataCenter.AssociationByDevice AS dv	ON dv.DCSDeviceID = tmp.DCSDeviceID
    ,   LATERAL
            (
                SELECT cls.CustID, cls.CategoryID
                FROM CTS_DataCenter.CTSCustomerClassification AS cls
                    INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
                WHERE cls.CTSCustID = tmp.CTSCustID AND cls.ParentID <> CONST_PARENTID_WRAPPER
                ORDER BY  cate.CustomerClassPriority ASC 
                        , cls.LastModifiedDate DESC
                LIMIT 1
            ) AS cate
        INNER JOIN CTS_DataCenter.CustomerCategorySettings AS st ON st.CategoryID = cate.CategoryID AND st.FlowNormalDgrAssociation = 1;





	INSERT IGNORE INTO Temp_Cust (CTSCustID/*, DCSDeviceID*/)
	SELECT DISTINCT tmp.CTSCustID/*, tmp.DCSDeviceID*/
	FROM Temp_CustDevice AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID
	WHERE cus.RoleID = CONST_ROLEID_MEMBER AND cus.IsInternal = 0;

	INSERT IGNORE INTO Temp_CustDgrAssociation(CTSCustID/*, ParentID, CategoryID*/)
	SELECT tmp.CTSCustID/*, cate.ParentID, cate.CategoryID*/
	FROM Temp_Cust AS tmp,
	LATERAL
		(
			SELECT cls.CustID, cls.CategoryID
			FROM CTS_DataCenter.CTSCustomerClassification AS cls
				INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
			WHERE cls.CTSCustID = tmp.CTSCustID AND cls.ParentID <> CONST_PARENTID_WRAPPER
			ORDER BY  cate.CustomerClassPriority ASC 
					, cls.LastModifiedDate DESC
			LIMIT 1
		) AS cate
	INNER JOIN CTS_DataCenter.CustomerCategorySettings AS st ON st.CategoryID = cate.CategoryID AND st.FlowNormalDgrAssociation = 1;

	SELECT MAX(DCSDeviceID)
	INTO op_LastScannedID
	FROM Temp_CustDevice;

	SET op_LastScannedID = IFNULL(op_LastScannedID, lv_LastScannedID);

    /*Return*/
    SELECT DISTINCT tmp.CTSCustID, tcd.DCSDeviceID
    FROM Temp_Cust AS tmp
        INNER JOIN Temp_CustDevice AS tcd ON tcd.CTSCustID = tmp.CTSCustID
        LEFT JOIN Temp_CustDgrAssociation AS cda ON cda.CTSCustID = tmp.CTSCustID
    WHERE cda.CTSCustID IS NOT NULL
        OR NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassification AS cls WHERE cls.CTSCustID = tmp.CTSCustID);

END$$
DELIMITER ;