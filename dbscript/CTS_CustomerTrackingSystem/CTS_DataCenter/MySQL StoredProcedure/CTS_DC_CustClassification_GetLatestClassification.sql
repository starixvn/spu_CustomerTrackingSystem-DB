/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_GetLatestClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestClassification`(IN ip_CustIDs TEXT)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201214@Irena.Vo	
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201214-20201230@Irena.Vo: Created. Update Input & Output params. Insert Error Log. Return All List CustID. For CC = -1 (Only get from existed CTSCustID) [RedmineID: #145951]
            
		Param's Explanation:
			call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification('1,2,1277,555555');
	*/ 
	DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_GetLatestClassification'; 
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    
	DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_ErrorMessage 	VARCHAR(200)  DEFAULT '0';
    DECLARE op_CodName 			VARCHAR(200)  DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS @op_No = NUMBER;
		GET DIAGNOSTICS CONDITION @op_No 
			op_ErrorNo 			= 	MYSQL_ERRNO
        ,	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES(lv_SPName, lv_CurrentDateTime, op_ErrorMessage, op_ErrorNo, 	JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_CustIDs));
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
    CREATE TEMPORARY TABLE 		Temp_Customers (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecords;
    CREATE TEMPORARY TABLE 		Temp_LatestRecords (
        	CustID			    BIGINT UNSIGNED PRIMARY KEY 
		,	ScannedTime			DATETIME
        ,	INDEX				IX_Temp_LatestRecords_ScannedTime(ScannedTime)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastestCategories;
    CREATE TEMPORARY TABLE 		Temp_LastestCategories (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,	CategoryID		    SMALLINT
        ,	ScannedTime			DATETIME
        ,   INDEX               IX_Temp_LastestCategories_ScannedTime_CategoryID(ScannedTime,CategoryID)
    );     
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE 		Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,   CustomerClass       SMALLINT
        ,	ScannedTime			DATETIME
    );    
    -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
    /* Insert existed Special CC before */
	INSERT INTO     Temp_CustomerClass (CustID, CustomerClass, ScannedTime)
    SELECT DISTINCT	temp.CustID,	sp.CustomerClass, sp.LastModifiedDate
    FROM 			Temp_Customers AS temp
    INNER JOIN 	    CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID;
    
    /*  Insert not existed Special CC or Category before */
	INSERT INTO     Temp_CustomerClass (CustID, CustomerClass, ScannedTime)
    SELECT DISTINCT	temp.CustID,	-1	AS CustomerClass, '1001-01-01 00:00:00'
    FROM 			Temp_Customers AS temp
    INNER JOIN 		CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID -- Existed CustID
    LEFT JOIN 	    CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
    LEFT JOIN 	    CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID IN (0, 200) -- PA & Normal
    WHERE 			sp.CustID IS NULL AND cate.CustID IS NULL;
    
    /* Insert not existed Special CC but have Category before*/
	-- Insert lastest of records
	INSERT INTO Temp_LatestRecords(CustID, ScannedTime)
	SELECT  DISTINCT temp.CustID,	MAX(cate.LastModifiedDate)
	FROM 		CTS_DataCenter.CTSCustomerClassification AS cate 
	INNER JOIN 	Temp_Customers AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID IN (0, 200) -- PA & Normal
    LEFT JOIN 	CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
	WHERE 		sp.CustID IS NULL
	GROUP BY 	temp.CustID; 
	
    -- Insert lastest customer category
	INSERT INTO Temp_LastestCategories(CustID, ScannedTime, CategoryID)
	SELECT 	DISTINCT temp.CustID,	temp.ScannedTime, MAX(cate.CategoryID) 
	FROM 		Temp_LatestRecords AS temp
	INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID
	WHERE 		temp.ScannedTime = cate.LastModifiedDate
	GROUP BY  	temp.CustID, temp.ScannedTime;
    
    -- Insert Customer Class
    INSERT INTO Temp_CustomerClass (CustID, CustomerClass, ScannedTime)
    SELECT DISTINCT temp.CustID,  map.CustomerClass, temp.ScannedTime
    FROM 			Temp_LastestCategories AS temp
    INNER JOIN 		CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID;
    
    /* Get Lastest Customer Class to sync in mainDB */
    SELECT DISTINCT	cc.CustId, cc.CustomerClass, cc.ScannedTime FROM Temp_CustomerClass AS cc;
END$$

DELIMITER ;