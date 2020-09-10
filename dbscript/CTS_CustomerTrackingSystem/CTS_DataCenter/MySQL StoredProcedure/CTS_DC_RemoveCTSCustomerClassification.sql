USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_RemoveCTSCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_RemoveCTSCustomerClassification`(
		IN ip_CustID			BIGINT UNSIGNED
	,   IN ip_CTSCustID			BIGINT UNSIGNED 
	,	IN ip_CategoryID		SMALLINT
	,	IN ip_CreatedBy 		INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu [Redmine ID: #132623]: Created 
            - 20200908@Irena.Vo [Redmine ID: #141020]: Delete VVIP OR All Category has Pin before (Include Customer Class) 
            
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_RemoveCTSCustomerClassification';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_DeleteCustomerClass;
	CREATE TEMPORARY TABLE Temp_DeleteCustomerClass
	(		CustID			    BIGINT UNSIGNED PRIMARY KEY
        ,	CustomerClass		INT
	);
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    SET SQL_SAFE_UPDATES = 0;
    
    -- Remove data from CTS_DataCenter.SpecialCustomerClass
    IF (ip_CategoryID IN (3, 213)) THEN
		DELETE 	sc
		FROM 	CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE 	sc.CustID = ip_CustID AND sc.CreatedFromFunction = 11; -- For VVIP
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(20, lv_SPName, CONCAT('Remove special customer class: ip_CTSCustID_ ', ip_CTSCustID) , lv_CurrentTime, ip_CreatedBy);
        
        -- Remove data from CTS_DataCenter.CTSCustomerClassification
		DELETE 	cate
		FROM 	CTS_DataCenter.CTSCustomerClassification AS cate
		WHERE 	cate.CustID = ip_CustID AND cate.CategoryID IN (3, 213);
	
    END IF;
    
     -- Insert customers removed CustomerClass
    INSERT INTO Temp_DeleteCustomerClass
    SELECT ip_CustID, -1
    WHERE ip_CategoryID IN (3, 213) -- For VVIP
          OR ip_CategoryID = (SELECT cate.CategoryID
                              FROM CTS_DataCenter.CTSCustomerClassification AS cate
                              INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cate.CategoryID = cc.CategoryID
                              WHERE cc.ParentID IN (50,200) AND cate.CustID = ip_CustID); -- For General
    
    -- Remove data from CTS_DataCenter.CTSCustomerClassification
    DELETE 	cate
    FROM 	CTS_DataCenter.CTSCustomerClassification AS cate
    WHERE 	cate.CustID = ip_CustID AND cate.CategoryID = ip_CategoryID;

    -- Insert history
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
        , 	ip_CategoryID
        , 	lv_CurrentTime
        , 	ip_CreatedBy
        ,   -100 -- -100: Delete
        ,   0 -- IsAuto
        ,   DATE(lv_CurrentTime);
   
    -- Insert log
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(12, lv_SPName, CONCAT('Delete CTSCustomerClassification: ip_CustID_', ip_CustID, ';ip_CategoryID_', ip_CategoryID), lv_CurrentTime, ip_CreatedBy);
	
    -- Return customers removed CustomerClass
    SELECT * FROM Temp_DeleteCustomerClass;
    
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$

DELIMITER ;