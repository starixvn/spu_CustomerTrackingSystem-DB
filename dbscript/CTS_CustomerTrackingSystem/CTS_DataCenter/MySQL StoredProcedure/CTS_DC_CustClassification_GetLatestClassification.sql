/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_GetLatestClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestClassification`(IN ip_CustomerCategorizes JSON)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201214@Irena.Vo	 
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201214@Irena.Vo: Created [RedmineID: #145951]
            
		Param's Explanation:
			- From CustID: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification_xtest('1,2,1277,555555', 1);
            - From CTSCustID: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification_xtest('1,2770811,2771325,555555', 0);
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategorizes;
    CREATE TEMPORARY TABLE Temp_CustomerCategorizes (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
		,   TypeID              SMALLINT UNSIGNED -- 1: Remove VVIP, 2: Remove CC, 3: Remove PA, 4: Other
        ,   IsExistedCC         BIT
        ,   IsExistedCate       BIT
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
        	CustID			    BIGINT UNSIGNED
		,	SportGroupID		SMALLINT
		,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY 		PK_Temp_LatestRecordOfCategory_CustID_SportGroupID(CustID,SportGroupID)
        ,	INDEX				IX_Temp_LatestRecordOfCategory_SportGroupID(SportGroupID)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastestCustomerCategory;
    CREATE TEMPORARY TABLE Temp_LastestCustomerCategory (
        	CustID				BIGINT UNSIGNED
		,	CategoryID		    SMALLINT
        ,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY         PK_Temp_LastestCustomerCategory_CustID(CustID)
        ,   INDEX               IX_Temp_LastestCustomerCategory_CategoryID(CategoryID)
    );     
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED
		,   CustomerClass       SMALLINT
        ,	ScannedTime	        DATETIME
        ,   IsRescanPA			BIT
        ,   IsRescanNormal		BIT
        ,	PRIMARY KEY 		PK_Temp_CustomerClass_CustID(CustID)
        ,	INDEX       		IX_Temp_CustomerClass_CustomerClass_ScannedTime(CustomerClass,ScannedTime)
    );    
    
	INSERT INTO Temp_CustomerCategorizes(CustID, TypeID)
	SELECT DISTINCT CASE WHEN cust.CTSCustID IS NOT NULL THEN cust.CustID
						 ELSE temp.CustID
					END 
                , temp.TypeID
	 FROM JSON_TABLE(ip_CustomerCategorizes,
		 "$[*]" COLUMNS(
			  CustID 		BIGINT UNSIGNED	PATH "$.CustId"
            , TypeID 		SMALLINT UNSIGNED PATH "$.TypeId"
		 )) AS temp
	LEFT JOIN CTS_DataCenter.CTSCustomer AS cust on cust.CTSCustID = temp.CustID;
   
   /*PREPARE DATA*/
   -- Update info: IsExistedCC & IsExistedCate
   UPDATE Temp_CustomerCategorizes AS temp
   LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
   LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
   SET 		temp.IsExistedCC = (CASE WHEN sp.CustID IS NOT NULL THEN 1
                                ELSE 0
							END)
		,	temp.IsExistedCate = (CASE WHEN cate.CustID IS NOT NULL THEN 1
                                ELSE 0
							END);
   
   -- Ignore Customer List existed CC
   DELETE temp
   FROM Temp_CustomerCategorizes AS temp
   WHERE temp.IsExistedCC = 1;
   
	-- Insert lastest of records
	INSERT INTO Temp_LatestRecordOfCategory(CustID, SportGroupID, LastModifiedDate)
	SELECT  	temp.CustID 
			,	cate.SportGroupID
			,	MAX(cate.LastModifiedDate)
	FROM CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN Temp_CustomerCategorizes AS temp ON temp.CustID = cate.CustID
	WHERE temp.IsExistedCate = 1 AND cate.CategoryID > 50 AND cate.CategoryID < 300
	GROUP BY temp.CustID, cate.CustID, cate.SportGroupID;
	
    -- Insert lastest customer category
	INSERT INTO Temp_LastestCustomerCategory(CustID, CategoryID, LastModifiedDate)
	SELECT 		temp.CustID
			,	MAX(cate.CategoryID) 
			,	temp.LastModifiedDate
	FROM Temp_LatestRecordOfCategory AS temp
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID
	WHERE temp.LastModifiedDate = cate.LastModifiedDate
	GROUP BY  temp.CustID, temp.SportGroupID, temp.LastModifiedDate;
    
    /*GET LIST CUSTID NEED TO RE-SCAN PA & NORMAL*/
    INSERT INTO Temp_CustomerClass (CustID,CustomerClass,IsRescanPA,IsRescanNormal)
    SELECT  	temp.CustID
           ,	-1	
           ,	CASE WHEN temp.TypeID IN (1, 2) THEN 1 -- Remove VVIP & Special
					ELSE 0 -- Remove PA
				END
		   ,	1
    FROM Temp_CustomerCategorizes AS temp
    WHERE temp.IsExistedCate = 0 AND temp.TypeID IN (1, 2, 3);
 
    /*GET LIST CUSTID NEED TO SYNC*/
    INSERT INTO Temp_CustomerClass(CustID,CustomerClass,ScannedTime,IsRescanPA,IsRescanNormal)
    SELECT DISTINCT temp.CustID
		    ,  	map.CustomerClass
			, 	temp.LastModifiedDate
            ,	0
            ,	0
    FROM Temp_LastestCustomerCategory AS temp
    INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID;
    
    /*GET RESULTS: LASTEST CUSTOMER CLASS*/
    SELECT DISTINCT 	cc.CustId
					, 	cc.CustomerClass
                    , 	cc.ScannedTime 
                    , 	cc.IsRescanPA
                    , 	cc.IsRescanNormal
    FROM Temp_CustomerClass AS cc;
  
END$$

DELIMITER ;