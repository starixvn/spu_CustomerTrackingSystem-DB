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
            - 20220607@Aries.Nguyen: Renovate PA process [Redmine ID: #172561]
            - 20220628@Aries.Nguyen: Update robot classification rule [Redmine ID: #174430]
            - 20220628@Aries.Nguyen: Update robot classification rule [Redmine ID: #174430]
			- 202208018@Long.Luu: Exclude wrapper categories from rescan PA flow [Redmine ID: #174219]

		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_ProblemAccountProbation_Insert ('[{"CustID": 123,"WinlossStatus": 1,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10}]');
	*/ 
    DECLARE	CONST_CATEGORYID_ROBOT 				INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_ROBOTLOSING 		INT DEFAULT 164;
    
    DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
    DECLARE CONST_SOURCETYPE_PROBLEMDIRECT		INT DEFAULT 31;
    DECLARE CONST_SOURCETYPE_PROBLEMAFFECT		INT DEFAULT 32;
    DECLARE CONST_SOURCETYPE_RESCANROBOT		INT DEFAULT 36;
    
    DECLARE CONST_PRIORITY_LICBA				INT DEFAULT 90;
    DECLARE CONST_CC_LICBA						INT DEFAULT 14;
    DECLARE CONST_CC_LICVIPDANGER				INT DEFAULT 99;
    DECLARE CONST_CC_LICVIPSUSPICIOUS			INT DEFAULT 101;    
    DECLARE CONST_SPORTGROUP_WRAPPER			INT DEFAULT 100;
    
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
        ,	IsDangerProbation 		BIT
        , 	WinlossStatus			SMALLINT /*LOSING  = 0,KEEPSTATE = 1, WINNING = 2;*/
        , 	IsLicensee				BIT
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        ,	IsDirect				BIT
        ,	IsLicenseeVIP			BIT
        ,	IsLicenseeBA			BIT
        , 	IsDataChanged			BIT 
        , 	PRIMARY KEY(CustID,CategoryID)  
    );  
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, CategoryID, RelevantCategoryID, SportGroupID,TargetCC,TargetDangerLevel1, IsDangerProbation, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect,IsLicenseeVIP,IsLicenseeBA, IsDataChanged)
	SELECT 	js.CustID
		,	cust.CTSCustID
        ,	clss.CategoryID
        ,	cate.RelevantCategoryID
        ,	clss.SportGroupID
        ,	desCate.TargetCC
        ,	desCate.TargetDangerLevel1
        ,	cate.IsDangerProbation
		, 	js.WinlossStatus 
        , 	js.TurnoverRM
        , 	js.WinlossRM
        , 	js.BetCount
        , 	js.ActiveDays
        ,	clss.IsDirect
        ,	cust.IsLicenseeVIP
        ,	cust.IsLicenseeBA
        ,	CASE WHEN js.WinlossStatus = 1 THEN 0 /*No Change*/
				 WHEN js.WinlossStatus = 0 AND cate.IsDangerProbation = 0 THEN 1  /*Lose + PA => Update */
				 WHEN js.WinlossStatus = 0 AND cate.IsDangerProbation = 1 THEN 0  /*Lose + Probation =>  No Change*/
                 WHEN js.WinlossStatus = 2 AND cate.IsDangerProbation = 0 THEN 0  /*Win + PA => No Change  */
                 WHEN js.WinlossStatus = 2 AND cate.IsDangerProbation = 1 THEN 1  /*Win + Probation => Update */
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
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON js.CustID = cust.CustID AND cust.CustSubID = 0 AND cust.IsInternal = 0
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = js.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.RelevantCategoryID IS NOT NULL,
        LATERAL (SELECT CASE WHEN cust.IsLicensee = 1 THEN tbl.ABIDangerLevel_Licensee  ELSE tbl.ABIDangerLevel_Credit END AS TargetDangerLevel1
					,	tbl.CustomerClass AS TargetCC
                 FROM CTS_DataCenter.CustomerCategory AS tbl 
                 WHERE cate.RelevantCategoryID = tbl.CategoryID 
                 LIMIT 1) AS desCate; 
    
    DELETE pa
    FROM Temp_PA AS pa
    WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.PinCustomerCategory AS pin WHERE pin.CTSCustID = pa.CTSCustID); 
        
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_PA AS tmp ON tmp.CustID = clss.CustID AND tmp.SportGroupID = clss.SportGroupID AND tmp.CategoryID = clss.CategoryID 
    SET 	clss.CategoryID = tmp.RelevantCategoryID
        ,	clss.LastModifiedBy = lv_CreatedBy
        ,	tmp.CategoryID = tmp.RelevantCategoryID 
    WHERE tmp.IsDataChanged = 1;

    UPDATE Temp_PA AS t 
		INNER JOIN CTS_DataCenter.CustomerCategory AS c ON t.CategoryID = c.CategoryID AND c.RelevantCategoryID IS NOT NULL
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS s ON t.CustID = s.CustID
    SET 	t.TargetCC = 	CASE
								WHEN s.CustomerClass IS NOT NULL THEN s.CustomerClass
                                WHEN t.IsLicenseeVIP = 1 AND c.IsDangerProbation = 1 THEN CONST_CC_LICVIPSUSPICIOUS
                                WHEN t.IsLicenseeVIP = 1 AND c.IsDangerProbation = 0 THEN CONST_CC_LICVIPDANGER
                                WHEN t.IsLicenseeBA = 1 AND c.Priority > CONST_PRIORITY_LICBA THEN CONST_CC_LICBA
                                ELSE t.TargetCC
							END;
    
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
		, 	CASE WHEN RelevantCategoryID IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING) THEN CONST_SOURCETYPE_RESCANROBOT
				 WHEN IsDirect = 1 THEN CONST_SOURCETYPE_PROBLEMDIRECT
				 ELSE CONST_SOURCETYPE_PROBLEMAFFECT END AS SourceTypeID
		,   IsDataChanged
        ,	TargetDangerLevel1
        ,	TurnoverRM
        ,	WinlossRM
        , 	BetCount
        , 	ActiveDays
	FROM Temp_PA
    WHERE IsDataChanged = 1
		AND SportGroupID <> CONST_SPORTGROUP_WRAPPER;

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustID
		, 	CTSCustID
		, 	CASE WHEN IsDataChanged = 1 THEN RelevantCategoryID ELSE CategoryID END AS CategoryID
		, 	SportGroupID
		, 	NOW() AS LastModifiedDate
		, 	lv_CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_UPDATE AS ActionType
		, 	1 AS IsAuto
		, 	NOW() AS InsertDate
		, 	TargetCC
		, 	CASE WHEN RelevantCategoryID IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING) THEN CONST_SOURCETYPE_RESCANROBOT
				 WHEN IsDirect = 1 THEN CONST_SOURCETYPE_PROBLEMDIRECT
				 ELSE CONST_SOURCETYPE_PROBLEMAFFECT END AS SourceTypeID
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
        ,	CASE WHEN CategoryID in (CONST_CATEGORYID_ROBOT,CONST_CATEGORYID_ROBOTLOSING) THEN 1
			ELSE 0 END AS ISRobot
    FROM Temp_PA
    WHERE IsDataChanged = 1; 
END$$
DELIMITER ;