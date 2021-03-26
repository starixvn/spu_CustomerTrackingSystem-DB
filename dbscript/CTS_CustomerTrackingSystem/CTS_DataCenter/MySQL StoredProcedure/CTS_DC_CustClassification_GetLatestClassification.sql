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
				- 20201214@Irena.Vo: Created. [RedmineID: #145951]
				- 20210326@Irena.Vo: Get Additional IsCateChanged, IsLicensee [RedmineID: #152249]
		Param's Explanation:
			call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification('1,2,1277,555555');
	*/ 
    DECLARE lv_ErrorMessage		VARCHAR(200) DEFAULT '0';
    DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            lv_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(1, lv_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_CustIDs));
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
    CREATE TEMPORARY TABLE 		Temp_Customers (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedSpecialCC;
    CREATE TEMPORARY TABLE 		Temp_ExistedSpecialCC (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
        ,   CustomerClass       SMALLINT
        ,	ScannedTime			DATETIME
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestScannedCategory;
    CREATE TEMPORARY TABLE 		Temp_LatestScannedCategory (
        	CustID			    BIGINT UNSIGNED PRIMARY KEY 
		,	ScannedTime			DATETIME
        ,	INDEX				IX_Temp_LatestScannedCategory_ScannedTime(ScannedTime)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedLastestCategory;
    CREATE TEMPORARY TABLE 		Temp_ExistedLastestCategory (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,	CategoryID		    SMALLINT
        ,	ScannedTime			DATETIME
        ,   INDEX               IX_Temp_ExistedLastestCategory_ScannedTime_CategoryID(ScannedTime,CategoryID)
    );     
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE 		Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,   CustomerClass       SMALLINT
        ,	ScannedTime			DATETIME
		,	IsCateChanged		BIT
		,	IsLicensee 			BIT
    );    
    
    -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
	/* Insert Existed Special CC */
	INSERT INTO  	Temp_ExistedSpecialCC (CustID, CustomerClass, ScannedTime)
    SELECT 			c.CustID,	sp.CustomerClass, sp.LastModifiedDate
    FROM 			Temp_Customers AS c
    INNER JOIN 	    CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = c.CustID;
    
    /* Insert Lastest Scanned Time for Category (if have) */
	INSERT INTO     Temp_LatestScannedCategory(CustID, ScannedTime)
	SELECT 			c.CustID,	MAX(cate.LastModifiedDate)
	FROM 			CTS_DataCenter.CTSCustomerClassification AS cate 
	INNER JOIN 		Temp_Customers AS c ON c.CustID = cate.CustID AND cate.SportGroupID IN (0, 200) -- PA & Normal
	GROUP BY 		c.CustID; 
    
    /* Update ScannedTime for Special CC (if have) and Insert Customer Class*/
    UPDATE     		Temp_ExistedSpecialCC AS es
    INNER JOIN 		Temp_LatestScannedCategory AS ls ON ls.CustID = es.CustID
    SET 	   		es.ScannedTime = GREATEST(es.ScannedTime,ls.ScannedTime);
    
    INSERT INTO 	Temp_CustomerClass (CustID, CustomerClass, ScannedTime)
    SELECT 			es.CustID, es.CustomerClass, es.ScannedTime
    FROM 			Temp_ExistedSpecialCC AS es;
    
    /* Insert Existed Lastest Category */
	INSERT INTO Temp_ExistedLastestCategory(CustID, ScannedTime, CategoryID)
	SELECT      ls.CustID,	ls.ScannedTime, MAX(cate.CategoryID) 
	FROM 		Temp_LatestScannedCategory AS ls
	INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = ls.CustID AND cate.SportGroupID IN (0, 200) -- PA & Normal
    LEFT JOIN	Temp_CustomerClass AS cc ON cc.CustID = ls.CustID
	WHERE 		cc.CustID IS NULL AND ls.ScannedTime = cate.LastModifiedDate -- Not existed Special CC
	GROUP BY  	ls.CustID, ls.ScannedTime;
    
    /* Mapping & Insert Customer Class */
    INSERT INTO    	Temp_CustomerClass (CustID, CustomerClass, ScannedTime)
    SELECT			ec.CustID,  map.CustomerClass, ec.ScannedTime
    FROM 			Temp_ExistedLastestCategory AS ec
    INNER JOIN 		CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = ec.CategoryID;
    
    /* Insert Customer Class = -1 */
	INSERT INTO     Temp_CustomerClass (CustID, CustomerClass, ScannedTime)
    SELECT 			temp.CustID,	-1	AS CustomerClass, CURRENT_TIME()
    FROM 			Temp_Customers AS temp
    INNER JOIN 		CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID -- Existed CustID
    LEFT JOIN 	    Temp_ExistedSpecialCC AS es ON es.CustID = temp.CustID -- Not existed Special CC
    LEFT JOIN 	    Temp_ExistedLastestCategory AS ec ON ec.CustID = temp.CustID -- Not existed Category
    WHERE 			es.CustID IS NULL AND ec.CustID IS NULL;
    
    /* Get Customer Category changed. */
	UPDATE Temp_CustomerClass AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.CustID = temp.CustID AND his.SportGroupID = 200 AND his.LastModifiedDate = temp.ScannedTime AND his.IsCateChanged = 1
	SET temp.IsCateChanged = 1;

	/*  Get Licensee Customers. */
	UPDATE Temp_CustomerClass AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0 -- get SubscriberID
		INNER JOIN CTS_DataCenter.MappingSubscriberSite AS map ON map.SubscriberID = cust.SubscriberID
	SET temp.IsLicensee = (CASE WHEN map.SubscriberGroupID = 2 THEN 1 -- Licensee
								ELSE 0 -- Credit, CN88
							END)
    WHERE temp.IsCateChanged = 1;
    
    /* Get Lastest Customer Class to sync in mainDB */
    SELECT DISTINCT	cc.CustId, cc.CustomerClass, cc.ScannedTime, cc.IsCateChanged, cc.IsLicensee FROM Temp_CustomerClass AS cc;
END$$

DELIMITER ;