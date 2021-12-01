/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_UpdateProblemAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_UpdateProblemAccount`(
		IN ip_CustInfo		JSON
	,	IN ip_ModifiedBy	INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	2021115@Aries.Nguyen
		Task:		Update Category when PA updated
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 2021115@Aries.Nguyen [Redmine ID: #156935]: Created
            
        Param's Explanation (filtered by):

        Example: 
			- CALL CTS_DC_CustClassification_UpdateProblemAccount('[{"CustID":1384, "FromReasonID":103, "ToReasonID":106}]',555);
*/   
	DECLARE	CONST_GROUP_PA 		INT DEFAULT 0;
    
    DECLARE CONST_ACTIONTYPE_INSERT 			INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 			INT DEFAULT 2;
	
    DECLARE CONST_SOURCETYPE_INSERTNAPPA 		INT DEFAULT 6;
    DECLARE	CONST_SOURCETYPE_REMOVENAPPA 		INT DEFAULT 8;
    DECLARE CONST_SOURCETYPE_UPDATENAPPA		INT DEFAULT 22;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustParam;    
	CREATE TEMPORARY TABLE Temp_CustParam( 	  
			CustID			INT UNSIGNED
		,	FromReasonID	INT  
        ,	ToReasonID		INT 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CheckExist;    
	CREATE TEMPORARY TABLE Temp_CheckExist( 	  
			CTSCustID		BIGINT UNSIGNED PRIMARY	KEY
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_CheckPin;    
	CREATE TEMPORARY TABLE Temp_CheckPin( 	  
			CTSCustID		BIGINT UNSIGNED PRIMARY	KEY
	);

    DROP TEMPORARY TABLE IF EXISTS Temp_Special;    
	CREATE TEMPORARY TABLE Temp_Special( 	  
			CTSCustID		    BIGINT UNSIGNED PRIMARY	KEY
        ,	CustomerClass		INT 
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo( 	
			CTSCustID				BIGINT UNSIGNED
		,	CustID					INT UNSIGNED
        ,	SubscriberID			INT UNSIGNED
        
		,	FromReasonID			INT  
        ,	FromCategoryID			INT  
        ,	HasFromCategoryID		BIT DEFAULT 0
        
        ,	ToReasonID				INT 
        ,	ToCategoryID			INT 
		,	ToCategoryGroup			INT
        ,	ToCustomerClass			INT 
        ,	HasToCategoryID			BIT DEFAULT 0
        ,	HasToCategoryIDOther	BIT DEFAULT 0
        
        ,	UserID					INT UNSIGNED
        ,	INDEX IX_Temp_CustInfo_CTSCustID(CTSCustID)
	);
    
    INSERT IGNORE INTO Temp_CustParam(CustID, FromReasonID, ToReasonID)
	SELECT	info.CustID
		, 	info.FromReasonID
        ,	info.ToReasonID
	FROM JSON_TABLE(ip_CustInfo,
		 "$[*]" COLUMNS(
				CustID			VARCHAR(50)		PATH "$.CustID" 
			, 	FromReasonID	INT				PATH "$.FromReasonID" 
            , 	ToReasonID		INT				PATH "$.ToReasonID")
	) AS info;
    
    INSERT IGNORE INTO Temp_CustInfo(CTSCustID, CustID,SubscriberID, FromReasonID, ToReasonID, UserID) 
    SELECT 	cus.CTSCustID
		,	cus.CustID
        ,	cus.SubscriberID
        ,	tmp.FromReasonID
        ,	tmp.ToReasonID
        ,	ip_ModifiedBy
	FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN Temp_CustParam AS tmp ON  cus.CustID = tmp.CustID AND cus.CustSubID = 0;

    INSERT IGNORE INTO Temp_CheckPin(CTSCustID)
    SELECT pin.CTSCustID
    FROM CTS_DataCenter.PinCustomerCategory AS pin
    WHERE EXISTS (SELECT 1 FROM Temp_CustInfo AS info WHERE info.CTSCustID = pin.CTSCustID);

    DELETE 
    FROM Temp_CustInfo AS info
    WHERE EXISTS (SELECT 1 FROM Temp_CheckPin AS pin WHERE pin.CTSCustID = info.CTSCustID);

    INSERT IGNORE INTO Temp_Special(CTSCustID, CustomerClass) 
    SELECT  sp.CTSCustID
        ,   sp.CustomerClass
    FROM CTS_DataCenter.SpecialCustomerClass AS sp
    WHERE EXISTS (SELECT 1 FROM Temp_CustInfo AS info WHERE info.CTSCustID = sp.CTSCustID);
    
	UPDATE Temp_CustInfo AS tmp 
	LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON tmp.FromReasonID = cc.ReasonID AND SourceType = 'NAP'
    SET 	tmp.FromCategoryID = cc.CategoryID;
	
    UPDATE Temp_CustInfo AS tmp 
	LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON tmp.ToReasonID = cc.ReasonID AND SourceType = 'NAP'
    SET 	tmp.ToCategoryID = cc.CategoryID
		,	tmp.ToCategoryGroup = cc.CategoryGroup;
    
    UPDATE Temp_CustInfo AS tmp 
	LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS cc ON tmp.ToCategoryID = cc.CategoryID
    SET 	tmp.ToCustomerClass = cc.CustomerClass;

    UPDATE Temp_CustInfo AS tmp 
	INNER JOIN Temp_Special AS cc ON tmp.CTSCustID = cc.CTSCustID
    SET 	tmp.ToCustomerClass = cc.CustomerClass;
    
    DELETE 
    FROM Temp_CustInfo AS tmp
    WHERE tmp.ToCategoryID IS NULL;

    UPDATE Temp_CustInfo
    SET FromCategoryID = -1
    WHERE FromCategoryID  IS NULL;

    /*Check FromReasonID exist*/
    INSERT IGNORE INTO Temp_CheckExist(CTSCustID)
    SELECT tmp.CTSCustID
    FROM Temp_CustInfo AS tmp
    WHERE EXISTS (SELECT 1 
				  FROM CTS_DataCenter.CTSCustomerClassification AS clss
                  WHERE clss.CTSCustID = tmp.CTSCustID 
					AND	clss.CategoryID = tmp.FromCategoryID);
                    
	UPDATE Temp_CustInfo AS info
    SET info.HasFromCategoryID = 1
    WHERE EXISTS (SELECT 1 FROM Temp_CheckExist AS tmp WHERE tmp.CTSCustID = info.CTSCustID);
    
    TRUNCATE TABLE Temp_CheckExist;
    
    /*Check ToReasonID exist*/
    INSERT IGNORE INTO Temp_CheckExist(CTSCustID)
    SELECT tmp.CTSCustID
    FROM Temp_CustInfo AS tmp
    WHERE EXISTS (SELECT 1 
				  FROM CTS_DataCenter.CTSCustomerClassification AS clss
				  WHERE clss.CTSCustID = tmp.CTSCustID
					AND	clss.CategoryID = tmp.ToCategoryID);
	
                    
	UPDATE Temp_CustInfo AS info
    SET info.HasToCategoryID = 1
    WHERE EXISTS (SELECT 1 FROM Temp_CheckExist AS tmp WHERE tmp.CTSCustID = info.CTSCustID);
    
    TRUNCATE TABLE Temp_CheckExist;
    /*Check ToCategoryID has other CategoryID in the same  category group*/
    
    
    INSERT IGNORE INTO Temp_CheckExist(CTSCustID)
    SELECT tmp.CTSCustID
    FROM Temp_CustInfo AS tmp
    WHERE EXISTS (SELECT 1 
				  FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID
				  WHERE clss.CTSCustID = tmp.CTSCustID
					AND	cate.CategoryGroup = tmp.ToCategoryGroup
                    AND cate.CategoryID != tmp.ToCategoryID);
    
    UPDATE Temp_CustInfo AS info
    SET info.HasToCategoryIDOther = 1
    WHERE EXISTS (SELECT 1 FROM Temp_CheckExist AS tmp WHERE tmp.CTSCustID = info.CTSCustID);
    
	/*************************Logic update category************************************/
    
    
	/*Case FromCategoryID not exist, ToCategoryID exist*/
    DELETE 
    FROM Temp_CustInfo AS tmp
    WHERE tmp.HasFromCategoryID = 0 AND tmp.HasToCategoryID = 1;
    
    DELETE 
    FROM Temp_CustInfo AS tmp
    WHERE tmp.FromCategoryID = tmp.ToCategoryID;
    
    /*Case FromCategoryID not exist, ToCategoryID not exist*/
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
	CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	tmp.CustID
		,	tmp.CTSCustID
		, 	tmp.SubscriberID
		, 	tmp.ToCategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		, 	NOW()
		, 	tmp.UserID
		, 	NOW()
		, 	tmp.UserID
		, 	NOW()
	FROM Temp_CustInfo AS tmp
    WHERE tmp.HasFromCategoryID = 0 
		AND tmp.HasToCategoryID = 0;   
    
    /*Case FromCategoryID exist, ToCategoryID exist*/
    
    DELETE 
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
    WHERE EXISTS (SELECT 1 
				  FROM Temp_CustInfo AS tmp 
				  WHERE tmp.CTSCustID = clss.CTSCustID 
					AND tmp.FromCategoryID =  clss.CategoryID
					AND tmp.HasFromCategoryID = 1  
                    AND tmp.HasToCategoryID = 1);
    
    /*Case FromCategoryID exist, ToCategoryID not exist*/	
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_CustInfo AS tmp ON 	 tmp.CTSCustID = clss.CTSCustID 
									AND  tmp.FromCategoryID =  clss.CategoryID 
                                    AND  tmp.HasFromCategoryID = 1 
                                    AND  tmp.HasToCategoryID = 0
	SET 	clss.CategoryID = tmp.ToCategoryID
		,	clss.LastModifiedDate = NOW()
        ,	clss.LastModifiedBy = tmp.UserID;
    

    /*Write History, Log*/
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, FromCategoryID, ToCategoryID, ActionType, TargetCC, SourceTypeID, IsDataChanged, LastModifiedDate,LastModifiedBy,  InsertDate)
	SELECT 	tmp.CustID
		, 	tmp.CTSCustID
		, 	CASE WHEN tmp.HasFromCategoryID = 1 AND  tmp.HasToCategoryID = 1  THEN tmp.FromCategoryID /*Delete From*/
			ELSE tmp.ToCategoryID  END AS CategoryID
		, 	CONST_GROUP_PA
		, 	tmp.FromCategoryID 
        ,	tmp.ToCategoryID
		, 	CASE WHEN tmp.HasFromCategoryID = 1 AND  tmp.HasToCategoryID = 0  THEN CONST_ACTIONTYPE_UPDATE 
				 WHEN tmp.HasFromCategoryID = 1 AND  tmp.HasToCategoryID = 1  THEN CONST_ACTIONTYPE_REMOVE
				 WHEN tmp.HasFromCategoryID = 0 AND  tmp.HasToCategoryID = 0  THEN CONST_ACTIONTYPE_INSERT  
            ELSE 0 END AS ActionType
		, 	tmp.ToCustomerClass
        ,	CONST_SOURCETYPE_UPDATENAPPA AS SourceTypeID
		,   1  AS IsDataChanged
        ,	NOW() AS LastModifiedDate
        ,	tmp.UserID
        ,	NOW() AS InsertDate
	FROM Temp_CustInfo AS tmp
    WHERE tmp.HasToCategoryIDOther = 0;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, FromCategoryID, ToCategoryID, ActionType, TargetCC, SourceTypeID, IsDataChanged, LastModifiedDate,LastModifiedBy,  InsertDate)
	SELECT 	tmp.CustID
		, 	tmp.CTSCustID
		, 	CASE WHEN tmp.HasFromCategoryID = 1 AND  tmp.HasToCategoryID = 1  THEN tmp.FromCategoryID /*Delete From*/
			ELSE tmp.ToCategoryID  END AS CategoryID
		, 	CONST_GROUP_PA
		, 	tmp.FromCategoryID 
        ,	tmp.ToCategoryID
		, 	CASE WHEN tmp.HasFromCategoryID = 1 AND  tmp.HasToCategoryID = 0  THEN CONST_ACTIONTYPE_UPDATE 
				 WHEN tmp.HasFromCategoryID = 1 AND  tmp.HasToCategoryID = 1  THEN CONST_ACTIONTYPE_REMOVE
				 WHEN tmp.HasFromCategoryID = 0 AND  tmp.HasToCategoryID = 0  THEN CONST_ACTIONTYPE_INSERT  
            ELSE 0 END AS ActionType
		, 	tmp.ToCustomerClass
        ,	CONST_SOURCETYPE_UPDATENAPPA AS SourceTypeID
		,   CASE WHEN tmp.HasToCategoryIDOther = 0  THEN 1
				 WHEN tmp.HasToCategoryIDOther = 1  THEN 0
			END AS IsDataChanged
        ,	NOW() AS LastModifiedDate
        ,	tmp.UserID
        ,	NOW() AS InsertDate
	FROM Temp_CustInfo AS tmp;

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, FromCategoryID, ToCategoryID, ActionType, TargetCC, SourceTypeID, IsDataChanged, LastModifiedDate,LastModifiedBy,  InsertDate)
	SELECT 	tmp.CustID
		, 	NULL
		, 	NULL
		, 	CONST_GROUP_PA
		, 	tmp.FromReasonID 
        ,	tmp.ToReasonID
		, 	-1
		, 	NULL
        ,	CONST_SOURCETYPE_UPDATENAPPA AS SourceTypeID
		,   0 AS IsDataChanged
        ,	NOW() AS LastModifiedDate
        ,	ip_ModifiedBy
        ,	NOW() AS InsertDate
	FROM Temp_CustParam AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM Temp_CustInfo AS info WHERE tmp.CustID = tmp.CustID);
    
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
    FROM Temp_CustInfo AS tmp;
END$$	

DELIMITER ;