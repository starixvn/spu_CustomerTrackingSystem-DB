/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Remove`(
    	IN ip_FromAction		TINYINT
    ,	IN ip_AffectDownline	BOOLEAN
    ,	IN ip_CustJson			JSON
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER 
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            - 20200908@Irena.Vo: Delete VVIP OR All Category has Pin before (Include Customer Class) [Redmine ID: #141020]
            - 20200921@Irena.Vo: Enhance SP & insert Probation Management flow [Redmine ID: #141755]
			- 20200923@Irena.Vo: Enhance SP [Redmine ID: #141755]
            - 20201201@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. Remove logic detail category. [Redmine ID: #145954]
            - 20201214-20201229@Irena.Vo: Insert History Log & Auto Unpin category. Insert Error Log [RedmineID: #145951]
            - 20210226@Irena.Vo: Update CategoryID from VVIP [RedmineID: #150454]
			- 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [RedmineID: #152965] 
			- 20210920@Aries.Nguyen: Split history log  [Redmine ID: #161890]
            - 10220418@Casey.Huynh: Add and Remove VVIP for Downline [Redmine ID: #159013]
            
		Param's Explanation:
			ip_FromAction: 1 From Web, 2 From Service
	*/ 
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Remove';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE 		Temp_Customer (
		 	CustID			BIGINT UNSIGNED		
         ,  CTSCustID 		BIGINT UNSIGNED
         ,	CreatedBy		BIGINT UNSIGNED
         ,	CategoryID		SMALLINT UNSIGNED
         
         ,	PRIMARY KEY PK_Temp_Customer(CustID)
         ,	INDEX IX_Temp_Customer_CTSCustID(CTSCustID)
	);
    
    /**************************************************************************************/
    INSERT INTO Temp_Customer(CustID, CTSCustID, CreatedBy) 
	SELECT 	DISTINCT temp.CustID, temp.CTSCustID, temp.CreatedBy
	FROM JSON_TABLE(ip_CustJson,
		 "$[*]" COLUMNS(
				CustID 		BIGINT UNSIGNED		PATH "$.CustID"
			,	CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
            ,	CreatedBy 	BIGINT UNSIGNED		PATH "$.CreatedBy"
            ,	CategoryID 	SMALLINT UNSIGNED	PATH "$.CategoryID"
            
		 )) AS temp;
         
    /*********************User Log*************************************************************/	
    IF ip_FromAction = 1 THEN
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT 10 AS LogTypeID
			, 	lv_SPName
			, 	CONCAT('Remove VVIP: CTSCustID', tmpCus.CTSCustID,'; AffectDownline_', ip_AffectDownline,'; CategoryID_', tmpCus.CategoryID)
            ,	lv_CurrentDateTime
            , 	tmpCus.CreatedBy
        FROM Temp_Customer AS tmpCus;
    END IF;
    /*************************************Remove VVIP*************************************/
	DELETE cls
    FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_Customer AS tmpCus ON cls.CustID = tmpCus.CustID AND tmpCus.CategoryID = ip_CategoryID;    	
	
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		,   tmpCus.CategoryID
		,   200
		, 	lv_CurrentDateTime
		, 	tmpCus.CreatedBy
		,   2
		,   0
		,   DATE(lv_CurrentDateTime)
		,   -1
		,   14
		,	1
	FROM Temp_Customer AS tmpCus;

	INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		,   tmpCus.CategoryID
		,   200
		, 	lv_CurrentDateTime
		, 	tmpCus.CreatedBy
		,   2
		,   0
		,   DATE(lv_CurrentDateTime)
		,   -1
		,   14
		,	1
	FROM Temp_Customer AS tmpCus;
		
	/*Auto Unpin*/
	DELETE pcc
    FROM CTS_DataCenter.PinCustomerCategory AS pcc
		INNER JOIN Temp_Customer AS tmpCus ON pcc.CTSCustID = tmpCus.CTSCustID;
        
	/*Return Remove VVIP List to Rescan*/
    SELECT tmpCus.CustID
	FROM Temp_Customer AS tmpCus;
    
END$$
DELIMITER ;