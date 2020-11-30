/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove`(
		IN ip_CustID			BIGINT UNSIGNED
	,   IN ip_CTSCustID			BIGINT UNSIGNED 
	,	IN ip_CategoryID		SMALLINT
	,	IN ip_CreatedBy 		INT
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
            
		Param's Explanation:
	*/ 

	/**********1. PREPARE PARAMS**********/
    DECLARE lv_CurrentDateTime DATETIME DEFAULT NOW();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_RemoveCTSCustomerClassification';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_GeneralCategory;
	CREATE TEMPORARY TABLE Temp_GeneralCategory
	(		CustID			    BIGINT UNSIGNED PRIMARY KEY
        ,	GeneralCategory		INT
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_DeleteCustomerClass;
	CREATE TEMPORARY TABLE Temp_DeleteCustomerClass
	(		CustID			    BIGINT UNSIGNED PRIMARY KEY
        ,	CustomerClass		INT
	);
    
    
	/**********2. INSERT GENERAL CATEGORY**********/
    INSERT INTO Temp_GeneralCategory
    SELECT cate.CustID, cate.CategoryID
	FROM CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cate.CategoryID = cc.CategoryID
    LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID IS NULL OR (sc.CustID = ip_CustID  AND CreatedFromFunction = 21) -- No get Delete -1 for CreatedFromFunction = 1
	WHERE cc.ParentID IN (50,200) AND cate.CustID = ip_CustID;
    
	/**********3. INSERT REMOVED CATEGORY**********/
    INSERT INTO Temp_DeleteCustomerClass
    SELECT ip_CustID, -1
    WHERE  ip_CategoryID = 213 -- For VVIP
           OR ip_CategoryID = (SELECT GeneralCategory FROM Temp_GeneralCategory); -- For General
    
   /**********4. ACTION FOR VVIP**********/
    IF (ip_CategoryID = 213) THEN
        -- Remove data CTSCustomerClassification
		DELETE 	cate
		FROM 	CTS_DataCenter.CTSCustomerClassification AS cate
		WHERE 	cate.CustID = ip_CustID AND cate.CategoryID  = 213;
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all classification: From ip_CustID_', ip_CustID, '; ip_CategoryID_', ip_CategoryID), lv_CurrentDateTime, ip_CreatedBy);

		-- Removed data CustomerClass
		DELETE 	sc
		FROM 	CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE 	sc.CustID = ip_CustID AND sc.CreatedFromFunction = 11; -- For VVIP
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all special customer class: From ip_CTSCustID_ ', ip_CTSCustID) , lv_CurrentDateTime, ip_CreatedBy);
        
    END IF;
    
	/**********5. ACTION FOR PROBATION**********/
	-- Removed data Probation List
    IF (ip_CategoryID = 10) THEN
		  DELETE pro
		  FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		  WHERE pro.CustID = ip_CustID AND pro.SportGroupID < 200;
          
		  INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		  VALUES(12, lv_SPName, CONCAT('Remove all probation list: From ip_CustID_ ', ip_CustID), lv_CurrentDateTime, ip_CreatedBy);
	END IF;
    
	IF (ip_CategoryID = 206) THEN  
		  DELETE pro
		  FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		  WHERE pro.CustID = ip_CustID AND pro.SportGroupID = 200;
          
		  INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	      VALUES(12, lv_SPName, CONCAT('Remove all probation list: From ip_CustID_ ', ip_CustID), lv_CurrentDateTime, ip_CreatedBy);
	END IF;

    /**********6. REMOVE CATEGORY AND INSERT HISTORY**********/
    DELETE 	cate
    FROM 	CTS_DataCenter.CTSCustomerClassification AS cate
    WHERE 	cate.CustID = ip_CustID AND cate.CategoryID = ip_CategoryID;

    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
        , 	ip_CategoryID
        , 	lv_CurrentDateTime
        , 	ip_CreatedBy
        ,   -100 -- -100: Delete
        ,   0 -- IsAuto
        ,   DATE(lv_CurrentDateTime);
   
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(12, lv_SPName, CONCAT('Remove classification: ip_CustID_', ip_CustID, ';ip_CategoryID_', ip_CategoryID), lv_CurrentDateTime, ip_CreatedBy);
	
    SELECT * FROM Temp_DeleteCustomerClass;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeleteCustomerClass;
	DROP TEMPORARY TABLE IF EXISTS Temp_GeneralCategory;
    
END$$

DELIMITER ;