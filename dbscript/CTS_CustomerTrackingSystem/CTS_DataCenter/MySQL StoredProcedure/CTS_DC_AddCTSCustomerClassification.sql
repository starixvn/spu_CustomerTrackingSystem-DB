USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_AddCTSCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_AddCTSCustomerClassification`(
	    IN ip_CustID			BIGINT UNSIGNED
    , 	IN ip_CTSCustID			BIGINT UNSIGNED	
    ,	IN ip_SubscriberID		INT
	, 	IN ip_SportGroupIDList 	VARCHAR(50)
	,	IN ip_CategoryID		SMALLINT
    , 	IN ip_Remark 			VARCHAR(300)
	,	IN ip_CreatedBy 		INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)

sp: BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu [Redmine ID: #132623]: Created 
			- 20200608@Casey.Huynh [Redmine ID: #]: Add parameter ip_CustID
					+ Rule "Delete Category "New Member" When Add Manaual Caterory"
            - 20200701@Casey.Huynh [Redmine ID: #]: 
					+ Remove Rule "Delete Category "New Member" When Add Manaual Caterory"
                    + Update History table
					+ Remove Verify VIP vs Smartpunter 
			- 20200908@Irena.Vo [Redmine ID: #141020]: Enhance insert manual for VVIP (include CustomerClass) 
		Param's Explanation:
	*/ 
   DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_AddCTSCustomerClassification';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;

	DROP TEMPORARY TABLE IF EXISTS Temp_SportGroupID;
    CREATE TEMPORARY TABLE Temp_SportGroupID (
		SportGroupID INT PRIMARY KEY
    );
    
    IF(ip_SportGroupIDList = '') THEN
       INSERT INTO Temp_SportGroupID (SportGroupID) VALUES (0);
	ELSE
		SET @sql = CONCAT("INSERT INTO Temp_SportGroupID (SportGroupID) VALUES ('", REPLACE(ip_SportGroupIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
	END IF;
    
	IF (SELECT COUNT(1) FROM CTS_DataCenter.CustomerCategory WHERE CategoryID = ip_CategoryID AND IsUsedManually = 0) > 0 THEN		
		SET op_ErrorMessage = 'This Category is not allowed for manually update!!!!'; 
        LEAVE sp;
    END IF;   
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET SQL_SAFE_UPDATES = 0;
    -- FOR VVIP
    IF (ip_CategoryID = 3) THEN
        -- Remove all category before: General & Detailed, Problem.
	    DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
		WHERE cate.CustID = ip_CustID; 

		  -- Remove old customer class before
        DELETE sc
		FROM CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE sc.CTSCustID = ip_CTSCustID AND sc.CreatedFromFunction = 1; 
        
        -- Insert for SpecialCustomerClass For VVIP
        INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
		SELECT 	ip_CTSCustID
			,	ip_CustID
			,	ip_CTSCustID
			,	ip_SubscriberID
			,	100
			,	ip_CreatedBy
			,	lv_CurrentTime
            ,   ip_CreatedBy
			,	lv_CurrentTime
			,   11; -- VVIP
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(19, lv_SPName, CONCAT('Insert SpecialCustomerClass: ip_CTSCustID = ', ip_CTSCustID, ';ip_CustomerClass = ', 100), lv_CurrentTime, ip_CreatedBy);
    END IF;
  
    -- Insert for CTSCustomerClassification
	INSERT INTO CTS_DataCenter.CTSCustomerClassification
    (CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
		, 	ip_SubscriberID
        , 	ip_CategoryID
        ,   SportGroupID
        , 	ip_Remark
        , 	lv_CurrentTime
        ,   ip_CreatedBy
        ,   lv_CurrentTime
        ,   ip_CreatedBy
        ,   lv_CurrentTime
	FROM Temp_SportGroupID;

   -- Insert history
   INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
        , 	ip_CategoryID
        , 	SportGroupID
        , 	lv_CurrentTime
        , 	ip_CreatedBy
        ,	0 -- Add new
        ,	0 -- IsAuto
        ,   lv_CurrentTime
	FROM Temp_SportGroupID;
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(10, 'CTS_DC_AddCTSCustomerClassification', CONCAT('Insert CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID,';ip_SportGroupIDList_', ip_SportGroupIDList,  ';ip_CategoryID_', ip_CategoryID, ';ip_Remark_', ip_Remark,')'), lv_CurrentTime, ip_CreatedBy);

    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;