/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_ProblemAccountProbation_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ProblemAccountProbation_Insert`(
		IN ip_ProblemAccount 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220328@Aries.Nguyen
		Task: Add new category/class for PA Probation [Redmine ID: #170468]
		DB: CTS_DataCenter
        
		Original:
		Revisions:
			- 20220328@Aries.Nguyen: Created [Redmine ID: #170468]

		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_ProblemAccountProbation_Insert ('[{"CustId": 123,"IsLosing": X,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10}]');
	*/ 
	DECLARE CONST_SOURCETYPE_SCANPA 			INT DEFAULT 23;
    DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
    
	DECLARE lv_CreatedBy 						INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 					DATETIME DEFAULT CURRENT_TIME(); 
   
	DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
			CustID					BIGINT UNSIGNED  
		, 	CTSCustID				BIGINT UNSIGNED 
        ,	SportGroupID			SMALLINT UNSIGNED DEFAULT 0 
        , 	CategoryID				SMALLINT UNSIGNED
        , 	RelationshipCategoryID 	SMALLINT UNSIGNED
        , 	TargetCC 				SMALLINT UNSIGNED
        , 	TargetDangerLevel1 		SMALLINT 
        ,	IsProbation 			BIT
        , 	IsLosing				BIT
        , 	IsLicensee				BIT
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        , 	IsDataChanged			BIT 
        , 	PRIMARY KEY(CustID,CategoryID)  
    );  
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, CategoryID, RelationshipCategoryID,TargetCC,TargetDangerLevel1, IsProbation, IsLosing, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDataChanged)
	SELECT 	js.CustID
		,	cust.CTSCustID
        ,	clss.CategoryID
        ,	cate.RelationshipCategoryID
        ,	desCate.TargetCC
        ,	desCate.TargetDangerLevel1
        ,	cate.IsProbation
		, 	js.IsLosing 
        , 	js.TurnoverRM
        , 	js.WinlossRM
        , 	js.BetCount
        , 	js.ActiveDays
        ,	CASE WHEN js.IsLosing = 0 AND cate.IsProbation = 0 THEN 0  /*Win + PA => Update*/
				 WHEN js.IsLosing = 0 AND cate.IsProbation = 1 THEN 1  /*Win + Probation => No Change*/
                 WHEN js.IsLosing = 1 AND cate.IsProbation = 0 THEN 1  /*Lose + PA => Update */
                 WHEN js.IsLosing = 1 AND cate.IsProbation = 1 THEN 0  /*Lose + Probation => No Change */
			END AS IsDataChanged
	FROM JSON_TABLE(ip_ProblemAccount,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED			PATH "$.CustID"
			,	IsLosing		BIT 					PATH "$.IsLosing"	
			,	TurnoverRM		DECIMAL(20,4) 			PATH "$.TurnoverRM"	
            ,	WinlossRM		DECIMAL(20,4) 			PATH "$.WinlossRM"	
			,	BetCount		BIGINT 					PATH "$.BetCount"	
            ,	ActiveDays		INT 					PATH "$.ActiveDays"	
		 )) AS js
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON js.CustID = cust.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = js.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.RelationshipCategoryID IS NOT NULL
        INNER JOIN MappingSubscriberSite AS mss ON cust.SiteID = mss.SiteID,
        LATERAL (SELECT CASE WHEN mss.SubscriberGroupID = 2 THEN tbl.ABIDangerLevel_Licensee 
							 ELSE tbl.ABIDangerLevel_Credit 
                        END AS TargetDangerLevel1
					,	tbl.CustomerClass AS TargetCC
                 FROM CTS_DataCenter.CustomerCategory AS tbl 
                 WHERE cate.RelationshipCategoryID = tbl.CategoryID 
                 LIMIT 1) AS desCate;
    
	CALL CTS_DC_ExcludeCustByCondition('Temp_PA');
	
    DELETE pa
    FROM Temp_PA AS pa
    WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory AS pin WHERE pin.CTSCustID = pa.CTSCustID); 
	
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_PA AS tmp ON tmp.CustID = clss.CustID AND tmp.SportGroupID = clss.SportGroupID AND tmp.CategoryID = clss.CategoryID 
    SET 	clss.CategoryID = tmp.RelationshipCategoryID
		,	clss.LastModifiedDate = NOW()
        ,	clss.LastModifiedBy = lv_CreatedBy
        ,	clss.CreatedDate = NOW()
    WHERE tmp.IsDataChanged = 1;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustID
		, 	CTSCustID
		, 	CategoryID
		, 	SportGroupID
		, 	NOW() AS LastModifiedDate
		, 	lv_CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_UPDATE AS ActionType
		, 	1 AS IsAuto
		, 	NOW() AS InsertDate
		, 	TargetCC
		, 	CONST_SOURCETYPE_SCANPA
		,   IsDataChanged
        ,	TargetDangerLevel1
        ,	TurnoverRM
        ,	WinlossRM
        , 	BetCount
        , 	ActiveDays
	FROM Temp_PA;

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustID
		, 	CTSCustID
		, 	CategoryID
		, 	SportGroupID
		, 	NOW() AS LastModifiedDate
		, 	lv_CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_UPDATE AS ActionType
		, 	1 AS IsAuto
		, 	NOW() AS InsertDate
		, 	TargetCC
		, 	CONST_SOURCETYPE_SCANPA
		,   IsDataChanged
        ,	TargetDangerLevel1
        ,	TurnoverRM
        ,	WinlossRM
        , 	BetCount
        , 	ActiveDays
	FROM Temp_PA;
    
	SELECT 	CustID
		,	CTSCustID
    FROM Temp_PA; 
END$$
DELIMITER ;