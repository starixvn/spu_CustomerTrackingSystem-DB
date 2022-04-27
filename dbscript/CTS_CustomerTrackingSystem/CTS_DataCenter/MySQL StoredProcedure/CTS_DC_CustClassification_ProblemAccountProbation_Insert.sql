/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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
            - 20220426@Aries.Nguyen: CTS - Daily PA Scan - Check Losing lead to show Created Date is wrong in PAM [Redmine ID: #171972]

		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_ProblemAccountProbation_Insert ('[{"CustID": 123,"WinlossStatus": 1,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10}]');
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
        , 	RelevantCategoryID 	    SMALLINT UNSIGNED
        , 	TargetCC 				SMALLINT UNSIGNED
        , 	TargetDangerLevel1 		SMALLINT 
        ,	IsProbation 			BIT
        , 	WinlossStatus			SMALLINT /*LOSING  = 0,KEEPSTATE = 1, WINNING = 2;*/
        , 	IsLicensee				BIT
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        , 	IsDataChanged			BIT 
        , 	PRIMARY KEY(CustID,CategoryID)  
    );  
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, CategoryID, RelevantCategoryID,TargetCC,TargetDangerLevel1, IsProbation, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDataChanged)
	SELECT 	js.CustID
		,	cust.CTSCustID
        ,	clss.CategoryID
        ,	cate.RelevantCategoryID
        ,	desCate.TargetCC
        ,	desCate.TargetDangerLevel1
        ,	cate.IsProbation
		, 	js.WinlossStatus 
        , 	js.TurnoverRM
        , 	js.WinlossRM
        , 	js.BetCount
        , 	js.ActiveDays
        ,	CASE WHEN js.WinlossStatus = 1 THEN 0 /*No Change*/
				 WHEN js.WinlossStatus = 0 AND cate.IsProbation = 0 THEN 1  /*Lose + PA => Update */
				 WHEN js.WinlossStatus = 0 AND cate.IsProbation = 1 THEN 0  /*Lose + Probation =>  No Change*/
                 WHEN js.WinlossStatus = 2 AND cate.IsProbation = 0 THEN 0  /*Win + PA => No Change  */
                 WHEN js.WinlossStatus = 2 AND cate.IsProbation = 1 THEN 1  /*Win + Probation => Update */
			END AS IsDataChanged
	FROM JSON_TABLE(ip_ProblemAccount,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED			PATH "$.CustID"
			,	WinlossStatus	SMALLINT 				PATH "$.WinlossStatus"	
			,	TurnoverRM		DECIMAL(20,4) 			PATH "$.TurnoverRM"	
            ,	WinlossRM		DECIMAL(20,4) 			PATH "$.WinlossRM"	
			,	BetCount		BIGINT 					PATH "$.BetCount"	
            ,	ActiveDays		INT 					PATH "$.ActiveDays"	
		 )) AS js
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON js.CustID = cust.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = js.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.RelevantCategoryID IS NOT NULL
        INNER JOIN MappingSubscriberSite AS mss ON cust.SiteID = mss.SiteID,
        LATERAL (SELECT CASE WHEN mss.SubscriberGroupID = 2 THEN tbl.ABIDangerLevel_Licensee 
							 ELSE tbl.ABIDangerLevel_Credit 
                        END AS TargetDangerLevel1
					,	tbl.CustomerClass AS TargetCC
                 FROM CTS_DataCenter.CustomerCategory AS tbl 
                 WHERE cate.RelevantCategoryID = tbl.CategoryID 
                 LIMIT 1) AS desCate;
    
	CALL CTS_DC_ExcludeCustByCondition('Temp_PA');
	
    DELETE pa
    FROM Temp_PA AS pa
    WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory AS pin WHERE pin.CTSCustID = pa.CTSCustID); 
	
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_PA AS tmp ON tmp.CustID = clss.CustID AND tmp.SportGroupID = clss.SportGroupID AND tmp.CategoryID = clss.CategoryID 
    SET 	clss.CategoryID = tmp.RelevantCategoryID
		,	clss.LastModifiedDate = NOW()
        ,	clss.LastModifiedBy = lv_CreatedBy
    WHERE tmp.IsDataChanged = 1;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustID
		, 	CTSCustID
		, 	RelevantCategoryID
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
	FROM Temp_PA
    WHERE IsDataChanged = 1;

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustID
		, 	CTSCustID
		, 	RelevantCategoryID
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
    
	SELECT 	DISTINCT
			CustID
		,	CTSCustID
    FROM Temp_PA
    WHERE IsDataChanged = 1; 
END$$
DELIMITER ;